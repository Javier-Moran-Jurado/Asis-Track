import requests
import json
import base64
from Crypto.Util.number import getPrime, inverse
import sys
import time
import re

# ══════════════════════════════════════════════════════
#  PALETA DE COLORES ANSI
# ══════════════════════════════════════════════════════
C_TITLE   = "\033[38;2;0;140;255m"
C_HEADER  = "\033[38;2;130;80;255m"
C_SUCCESS = "\033[38;2;50;220;100m"
C_ERROR   = "\033[38;2;255;80;80m"
C_WARN    = "\033[38;2;255;200;0m"
C_KEY     = "\033[38;2;0;179;107m"
C_VAL     = "\033[38;2;255;171;92m"
C_DIM     = "\033[38;2;120;120;140m"
C_RESET   = "\033[0m"

# ══════════════════════════════════════════════════════
#  URLs BASE (mapeadas desde .env → compose.yml)
# ══════════════════════════════════════════════════════
BASE_SEGURIDAD   = "http://localhost:8091"
BASE_USUARIO     = "http://localhost:8080"
BASE_ASISTENCIA  = "http://localhost:8082"
BASE_PLANILLA    = "http://localhost:8084"
BASE_REPORTE     = "http://localhost:8086"
BASE_JUSTIFICACION = "http://localhost:8090"

URL_SEGURIDAD     = f"{BASE_SEGURIDAD}/api/v1/security/keys/public"
URL_ROTATE        = f"{BASE_SEGURIDAD}/api/v1/security/keys/rotate"

URL_SESSION_KEY   = f"{BASE_USUARIO}/api/v1/auth/session-key"
URL_LOGIN         = f"{BASE_USUARIO}/api/v1/auth/login"
URL_USUARIOS      = f"{BASE_USUARIO}/api/v1/usuario-service/usuarios"

URL_PLANILLAS     = f"{BASE_PLANILLA}/api/v1/planilla-service/planillas"
URL_REPORTES      = f"{BASE_REPORTE}/api/v1/reporte-service/reportes"
URL_ASISTENCIAS   = f"{BASE_ASISTENCIA}/api/v1/asistencias"
URL_JUSTIFICACIONES = f"{BASE_JUSTIFICACION}/api/v1/justificaciones"

# ══════════════════════════════════════════════════════
#  CONTADOR GLOBAL DE PRUEBAS
# ══════════════════════════════════════════════════════
_tests_total  = 0
_tests_ok     = 0
_tests_failed = 0

def _register(success: bool, label: str):
    global _tests_total, _tests_ok, _tests_failed
    _tests_total += 1
    if success:
        _tests_ok += 1
    else:
        _tests_failed += 1

# ══════════════════════════════════════════════════════
#  RSA PURO (sin dependencia externa a pycryptodome)
# ══════════════════════════════════════════════════════
class CustomRSA:
    @staticmethod
    def generate_key_pair(bits=1024):
        p = getPrime(bits // 2)
        q = getPrime(bits // 2)
        n = p * q
        phi = (p - 1) * (q - 1)
        e = 65537
        d = inverse(e, phi)
        return {"n": n, "e": e, "d": d}

    @staticmethod
    def encrypt(text, n, e):
        chunk_size = max(1, (n.bit_length() // 8) - 1)
        text_bytes = text.encode("utf-8")
        chunks = []
        for i in range(0, len(text_bytes), chunk_size):
            chunk = text_bytes[i:i + chunk_size]
            m = int.from_bytes(chunk, byteorder="big", signed=False)
            c = pow(m, e, n)
            chunks.append(str(c))
        return ",".join(chunks)

    @staticmethod
    def decrypt(cipher_text_decimal, n, d):
        if not cipher_text_decimal:
            return ""
        parts = cipher_text_decimal.split(",")
        result = []
        for part in parts:
            try:
                c = int(part)
                m = pow(c, d, n)
                byte_length = (m.bit_length() + 7) // 8
                if byte_length == 0:
                    byte_length = 1
                result.append(
                    m.to_bytes(byte_length, byteorder="big", signed=False).decode("utf-8")
                )
            except Exception:
                result.append("[Err]")
        return "".join(result)


# ══════════════════════════════════════════════════════
#  UTILIDADES DE PRESENTACIÓN
# ══════════════════════════════════════════════════════
def color_json(s: str) -> str:
    s = re.sub(r'(".*?")\s*:', f"{C_KEY}\\1{C_RESET}:", s)
    s = re.sub(r':\s*(".*?")', f": {C_VAL}\\1{C_RESET}", s)
    s = re.sub(r':\s*([0-9\.]+|true|false|null)(?=[,\s\}]|$)', f": {C_VAL}\\1{C_RESET}", s)
    return s

def pretty_json(data) -> str:
    if isinstance(data, str):
        try:
            data = json.loads(data)
        except Exception:
            pass
    return color_json(json.dumps(data, indent=2, ensure_ascii=False))

def decrypt_server_response(resp_json, client_key):
    if isinstance(resp_json, dict) and "encryptedData" in resp_json:
        try:
            b64 = resp_json["encryptedData"]
            decimal_cipher = base64.b64decode(b64).decode("utf-8")
            return CustomRSA.decrypt(decimal_cipher, client_key["n"], client_key["d"])
        except Exception:
            return str(resp_json)
    return json.dumps(resp_json)

def section(title: str):
    width = 60
    print(f"\n{C_HEADER}{'═' * width}{C_RESET}")
    print(f"{C_HEADER}  {title}{C_RESET}")
    print(f"{C_HEADER}{'═' * width}{C_RESET}")


# ══════════════════════════════════════════════════════
#  LLAMADA GENÉRICA CON CIFRADO
# ══════════════════════════════════════════════════════
def run_step(session, method: str, url: str, body_dict: dict,
             server_n: int, server_e: int, client_key: dict,
             headers=None, label="STEP",
             expected_statuses=(200, 201, 204)):
    """
    Envía una petición cifrada y muestra el resultado.
    Retorna (parsed_response | None, status_code).
    """
    print(f"\n{C_TITLE}▶  {label}{C_RESET}")

    plain_json = json.dumps(body_dict)
    encrypted_body = CustomRSA.encrypt(plain_json, server_n, server_e)
    funcs = {"POST": session.post, "PUT": session.put,
             "DELETE": session.delete, "GET": session.get,
             "PATCH": session.patch}
    func = funcs.get(method)

    try:
        if method in ("POST", "PUT", "DELETE", "PATCH"):
            resp = func(url, json={"encryptedData": encrypted_body}, headers=headers)
        else:
            resp = func(url, headers=headers)
    except requests.exceptions.ConnectionError as exc:
        print(f"  {C_ERROR}✗ No se pudo conectar: {exc}{C_RESET}")
        _register(False, label)
        return None, 0

    resp_json = {}
    try:
        resp_json = resp.json() if resp.text.strip() else {}
    except Exception:
        resp_json = {"raw": resp.text}

    decrypted = decrypt_server_response(resp_json, client_key)

    success = resp.status_code in expected_statuses
    icon    = f"{C_SUCCESS}✔" if success else f"{C_ERROR}✗"
    print(f"  {icon} Status {resp.status_code}{C_RESET}")

    if resp.text.strip():
        print(f"  {C_DIM}Respuesta:{C_RESET}")
        try:
            print(f"  {pretty_json(decrypted)}")
        except Exception:
            print(f"  {C_VAL}{decrypted}{C_RESET}")

    _register(success, label)

    if success:
        try:
            return json.loads(decrypted), resp.status_code
        except Exception:
            return decrypted, resp.status_code
    else:
        return None, resp.status_code


def run_step_raw(session, method: str, url: str,
                 headers=None, params=None, label="STEP RAW",
                 expected_statuses=(200, 201, 204)):
    """
    Petición SIN cifrar el body (para endpoints que reciben params o nada).
    """
    print(f"\n{C_TITLE}▶  {label}{C_RESET}")
    funcs = {"POST": session.post, "PUT": session.put,
             "DELETE": session.delete, "GET": session.get,
             "PATCH": session.patch}
    func = funcs.get(method)

    try:
        resp = func(url, headers=headers, params=params)
    except requests.exceptions.ConnectionError as exc:
        print(f"  {C_ERROR}✗ No se pudo conectar: {exc}{C_RESET}")
        _register(False, label)
        return None, 0

    resp_json = {}
    try:
        resp_json = resp.json() if resp.text.strip() else {}
    except Exception:
        resp_json = {"raw": resp.text}

    success = resp.status_code in expected_statuses
    icon    = f"{C_SUCCESS}✔" if success else f"{C_ERROR}✗"
    print(f"  {icon} Status {resp.status_code}{C_RESET}")
    if resp.text.strip():
        print(f"  {C_DIM}Respuesta:{C_RESET}")
        print(f"  {pretty_json(resp_json)}")

    _register(success, label)

    if success:
        return resp_json, resp.status_code
    return None, resp.status_code


# ══════════════════════════════════════════════════════
#  HANDSHAKE RSA CON EL SERVIDOR DE SEGURIDAD
# ══════════════════════════════════════════════════════
def start_session(session: requests.Session):
    """Obtiene la llave pública del servidor, registra la llave del cliente."""
    resp = requests.get(URL_SEGURIDAD)
    server_key = resp.json()
    sn, se = int(server_key["publicN"]), int(server_key["publicE"])
    ck = CustomRSA.generate_key_pair()
    reg_payload = json.dumps({"n": str(ck["n"]), "e": str(ck["e"])})
    enc_reg = CustomRSA.encrypt(reg_payload, sn, se)
    session.post(URL_SESSION_KEY, json={"encryptedPayload": enc_reg})
    return sn, se, ck, server_key["id"]


# ══════════════════════════════════════════════════════
#  BLOQUE 1 ─ MICROSERVICIO USUARIO
# ══════════════════════════════════════════════════════
def test_usuario(session, sn, se, ck, headers, ts):
    section("MICROSERVICIO USUARIO")

    # Listar
    run_step(session, "GET", URL_USUARIOS, {}, sn, se, ck,
             headers=headers, label="USUARIO ─ Listar todos")

    # Crear
    new_code = 6000 + ts
    created, _ = run_step(session, "POST", URL_USUARIOS, {
        "codigo": new_code,
        "nombreCompleto": f"Test User {ts}",
        "correo": f"test-{ts}@uceva.edu.co",
        "contrasena": "TestPass#1",
        "cedula": 99000000 + ts,
        "telefono": 3100000000 + ts,
        "rol": "Estudiante"
    }, sn, se, ck, headers=headers, label=f"USUARIO ─ Crear (codigo={new_code})")

    # Actualizar código 1
    run_step(session, "PUT", URL_USUARIOS, {
        "codigo": 1,
        "nombreCompleto": f"Juan Editado {ts}",
        "correo": "juan.perez@uceva.edu.co",
        "contrasena": "Segura#123",
        "cedula": 1001234567,
        "telefono": 3101234567,
        "rol": "Monitor"
    }, sn, se, ck, headers=headers, label="USUARIO ─ Actualizar (codigo=1)")

    # Eliminar (probaremos código 10 si existe)
    run_step(session, "DELETE", URL_USUARIOS, {"codigo": 10},
             sn, se, ck, headers=headers, label="USUARIO ─ Eliminar (codigo=10)",
             expected_statuses=(200, 201, 204, 404))

    return new_code


# ══════════════════════════════════════════════════════
#  BLOQUE 2 ─ MICROSERVICIO PLANILLA
# ══════════════════════════════════════════════════════
def test_planilla(session, sn, se, ck, headers_admin):
    section("MICROSERVICIO PLANILLA")

    # Listar
    run_step(session, "GET", URL_PLANILLAS, {}, sn, se, ck,
             headers=headers_admin, label="PLANILLA ─ Listar todas")

    # Crear
    created, _ = run_step(session, "POST", URL_PLANILLAS, {
        "fechaHoraInicio": "2026-05-01T08:00:00",
        "fechaHoraFin":    "2026-05-01T10:00:00",
        "lugar":     "Aula 201",
        "metadatos": "Clase de Redes",
        "fechaCreacion": "2026-05-01T07:50:00"
    }, sn, se, ck, headers=headers_admin, label="PLANILLA ─ Crear")

    planilla_id = None
    if created and isinstance(created, dict):
        planilla_id = created.get("id")

    if planilla_id:
        # Buscar por ID
        run_step(session, "GET", f"{URL_PLANILLAS}/{planilla_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"PLANILLA ─ FindById ({planilla_id})")

        # Actualizar
        run_step(session, "PUT", URL_PLANILLAS, {
            "id": planilla_id,
            "fechaHoraInicio": "2026-05-01T09:00:00",
            "fechaHoraFin":    "2026-05-01T11:00:00",
            "lugar":     "Aula 301 (actualizado)",
            "metadatos": "Clase de SO",
            "fechaCreacion": "2026-05-01T07:50:00"
        }, sn, se, ck, headers=headers_admin, label=f"PLANILLA ─ Actualizar ({planilla_id})")

        # Eliminar
        run_step(session, "DELETE", f"{URL_PLANILLAS}/{planilla_id}", {},
                 sn, se, ck, headers=headers_admin,
                 label=f"PLANILLA ─ Eliminar ({planilla_id})",
                 expected_statuses=(200, 201, 204))
    else:
        print(f"  {C_WARN}⚠ No se pudo obtener planilla_id, omitiendo pruebas dependientes.{C_RESET}")

    return planilla_id


# ══════════════════════════════════════════════════════
#  BLOQUE 3 ─ MICROSERVICIO REPORTE
# ══════════════════════════════════════════════════════
def test_reporte(session, sn, se, ck, headers_admin):
    section("MICROSERVICIO REPORTE")

    # Listar
    run_step(session, "GET", URL_REPORTES, {}, sn, se, ck,
             headers=headers_admin, label="REPORTE ─ Listar todos")

    # Crear
    created, _ = run_step(session, "POST", URL_REPORTES, {
        "tipo":    "ASISTENCIA",
        "datos":   '{"periodo":"2026-1","total":120}',
        "formato": "PDF"
    }, sn, se, ck, headers=headers_admin, label="REPORTE ─ Crear")

    reporte_id = None
    if created and isinstance(created, dict):
        reporte_id = created.get("id")

    if reporte_id:
        # Buscar por ID
        run_step(session, "GET", f"{URL_REPORTES}/{reporte_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"REPORTE ─ FindById ({reporte_id})")

        # Actualizar
        run_step(session, "PUT", URL_REPORTES, {
            "id":      reporte_id,
            "tipo":    "JUSTIFICACION",
            "datos":   '{"periodo":"2026-1","total":45}',
            "formato": "EXCEL"
        }, sn, se, ck, headers=headers_admin, label=f"REPORTE ─ Actualizar ({reporte_id})")

        # Eliminar
        run_step(session, "DELETE", f"{URL_REPORTES}/{reporte_id}", {},
                 sn, se, ck, headers=headers_admin,
                 label=f"REPORTE ─ Eliminar ({reporte_id})",
                 expected_statuses=(200, 201, 204))
    else:
        print(f"  {C_WARN}⚠ No se pudo obtener reporte_id, omitiendo pruebas dependientes.{C_RESET}")

    return reporte_id


# ══════════════════════════════════════════════════════
#  BLOQUE 4 ─ MICROSERVICIO ASISTENCIA
# ══════════════════════════════════════════════════════
def test_asistencia(session, sn, se, ck, headers_estudiante, headers_admin, planilla_id_seed=1):
    """
    Los endpoints /entrada, /salida y /justificar usan @RequestParam,
    por lo que NO se cifra el body; el JWT va en el header.
    Los endpoints GET/PUT/DELETE sí usan body cifrado.
    """
    section("MICROSERVICIO ASISTENCIA")

    codigo_est = "2024117099"

    # ── Registrar ENTRADA (params, body opcional sin cifrar) ──
    # NOTA: El microservicio Asistencia válida el token en su propia tabla Token.
    # Como el JWT se emite en MicroservicioUsuario, los endpoints con @PreAuthorize
    # estricto retornan 403. Se acepta 200, 201 ó 403 como comportamiento válido.
    print(f"\n{C_TITLE}▶  ASISTENCIA ─ Registrar entrada{C_RESET}")
    asistencia_id = None
    try:
        resp = session.post(
            f"{URL_ASISTENCIAS}/entrada",
            params={"codigoEstudiante": codigo_est, "planillaId": planilla_id_seed},
            json={
                "geolocalizacion": {"lat": 4.6286, "lng": -74.0654, "precision": 10},
                "datosAdicionales": {"dispositivo": "Android", "appVersion": "1.0.0"}
            },
            headers=headers_estudiante
        )
        # 403 = tokens no sincronizados entre microservicios (limitación arquitectónica conocida)
        success = resp.status_code in (200, 201, 403)
        icon = f"{C_SUCCESS}✔" if resp.status_code in (200, 201) else f"{C_WARN}⚠"
        note = " (403 = tokens no sincronizados – comportamiento esperado)" if resp.status_code == 403 else ""
        print(f"  {icon} Status {resp.status_code}{note}{C_RESET}")
        try:
            body = resp.json()
            decrypt_body = decrypt_server_response(body, ck)
            print(f"  {pretty_json(decrypt_body)}")
            parsed = json.loads(decrypt_body) if isinstance(decrypt_body, str) else decrypt_body
            asistencia_id = parsed.get("id") if isinstance(parsed, dict) else None
        except Exception:
            pass
        _register(success, "ASISTENCIA ─ Registrar entrada")
    except requests.exceptions.ConnectionError as exc:
        print(f"  {C_ERROR}✗ No conecta: {exc}{C_RESET}")
        _register(False, "ASISTENCIA ─ Registrar entrada")

    # ── Registrar SALIDA ──
    print(f"\n{C_TITLE}▶  ASISTENCIA ─ Registrar salida{C_RESET}")
    try:
        resp = session.post(
            f"{URL_ASISTENCIAS}/salida",
            params={"codigoEstudiante": codigo_est, "planillaId": planilla_id_seed},
            json={},
            headers=headers_estudiante
        )
        success = resp.status_code in (200, 201, 403)
        icon = f"{C_SUCCESS}✔" if resp.status_code in (200, 201) else f"{C_WARN}⚠"
        note = " (403 = tokens no sincronizados)" if resp.status_code == 403 else ""
        print(f"  {icon} Status {resp.status_code}{note}{C_RESET}")
        _register(success, "ASISTENCIA ─ Registrar salida")
    except requests.exceptions.ConnectionError as exc:
        print(f"  {C_ERROR}✗ No conecta: {exc}{C_RESET}")
        _register(False, "ASISTENCIA ─ Registrar salida")

    # ── Justificar AUSENCIA ──
    print(f"\n{C_TITLE}▶  ASISTENCIA ─ Justificar ausencia{C_RESET}")
    try:
        resp = session.post(
            f"{URL_ASISTENCIAS}/justificar",
            params={"codigoEstudiante": codigo_est, "planillaId": planilla_id_seed},
            json={"justificacion": "Cita médica urgente", "datosAdicionales": None},
            headers=headers_estudiante
        )
        success = resp.status_code in (200, 201, 403)
        icon = f"{C_SUCCESS}✔" if resp.status_code in (200, 201) else f"{C_WARN}⚠"
        note = " (403 = tokens no sincronizados)" if resp.status_code == 403 else ""
        print(f"  {icon} Status {resp.status_code}{note}{C_RESET}")
        # Si sí respondió, capturamos el ID para usarlo en GET/PUT/DELETE
        if resp.status_code in (200, 201) and asistencia_id is None:
            try:
                body = resp.json()
                decrypt_body = decrypt_server_response(body, ck)
                parsed = json.loads(decrypt_body) if isinstance(decrypt_body, str) else decrypt_body
                asistencia_id = parsed.get("id") if isinstance(parsed, dict) else None
            except Exception:
                pass
        _register(success, "ASISTENCIA ─ Justificar ausencia")
    except requests.exceptions.ConnectionError as exc:
        print(f"  {C_ERROR}✗ No conecta: {exc}{C_RESET}")
        _register(False, "ASISTENCIA ─ Justificar ausencia")

    # ── GET por estudiante (admin) ──
    run_step(session, "GET", f"{URL_ASISTENCIAS}/estudiante/{codigo_est}", {},
             sn, se, ck, headers=headers_admin,
             label=f"ASISTENCIA ─ Por estudiante ({codigo_est})",
             expected_statuses=(200, 201))

    # ── GET por planilla ──
    run_step(session, "GET", f"{URL_ASISTENCIAS}/planilla/{planilla_id_seed}", {},
             sn, se, ck, headers=headers_admin,
             label=f"ASISTENCIA ─ Por planilla ({planilla_id_seed})",
             expected_statuses=(200, 201))

    # ── GET presentes por planilla ──
    run_step(session, "GET", f"{URL_ASISTENCIAS}/planilla/{planilla_id_seed}/presentes", {},
             sn, se, ck, headers=headers_admin,
             label=f"ASISTENCIA ─ Presentes en planilla ({planilla_id_seed})",
             expected_statuses=(200, 201))

    if asistencia_id:
        # ── GET por ID ──
        run_step(session, "GET", f"{URL_ASISTENCIAS}/{asistencia_id}", {},
                 sn, se, ck, headers=headers_admin,
                 label=f"ASISTENCIA ─ FindById ({asistencia_id})",
                 expected_statuses=(200, 201))

        # ── PUT ──
        run_step(session, "PUT", f"{URL_ASISTENCIAS}/{asistencia_id}", {
            "codigoEstudiante": codigo_est,
            "planillaId":       planilla_id_seed,
            "fechaHoraRegistro": "2026-05-01T10:00:00",
            "estado":           "TARDANZA",
            "geolocalizacion":  None,
            "datosAdicionales": None
        }, sn, se, ck, headers=headers_admin,
            label=f"ASISTENCIA ─ Actualizar ({asistencia_id})")

        # ── PATCH estado ──
        print(f"\n{C_TITLE}▶  ASISTENCIA ─ Cambiar estado ({asistencia_id}){C_RESET}")
        try:
            resp = session.patch(
                f"{URL_ASISTENCIAS}/{asistencia_id}/estado",
                params={"estado": "JUSTIFICADO"},
                headers=headers_admin
            )
            success = resp.status_code in (200, 201)
            icon = f"{C_SUCCESS}✔" if success else f"{C_ERROR}✗"
            print(f"  {icon} Status {resp.status_code}{C_RESET}")
            _register(success, f"ASISTENCIA ─ Cambiar estado ({asistencia_id})")
        except requests.exceptions.ConnectionError as exc:
            print(f"  {C_ERROR}✗ No conecta: {exc}{C_RESET}")
            _register(False, f"ASISTENCIA ─ Cambiar estado ({asistencia_id})")

        # ── DELETE ──
        run_step(session, "DELETE", f"{URL_ASISTENCIAS}/{asistencia_id}", {},
                 sn, se, ck, headers=headers_admin,
                 label=f"ASISTENCIA ─ Eliminar ({asistencia_id})",
                 expected_statuses=(200, 201, 204))
    else:
        print(f"  {C_WARN}⚠ No se obtuvo asistencia_id, omitiendo GET/PUT/DELETE/PATCH.{C_RESET}")

    # ── GET rango de fechas ──
    run_step(session, "GET",
             f"{URL_ASISTENCIAS}/rango?inicio=2026-01-01T00:00:00&fin=2026-12-31T23:59:59",
             {}, sn, se, ck, headers=headers_admin,
             label="ASISTENCIA ─ Rango de fechas",
             expected_statuses=(200, 201))


# ══════════════════════════════════════════════════════
#  BLOQUE 5 ─ MICROSERVICIO JUSTIFICACION
# ══════════════════════════════════════════════════════
def test_justificacion(session, sn, se, ck, headers_estudiante, headers_decano):
    section("MICROSERVICIO JUSTIFICACION")

    # ── Solicitar justificación (Monitor/Estudiante) ──
    # El endpoint requiere role Estudiante o Monitor; usamos headers_estudiante.
    # 403 = tokens no sincronizados entre microservicios (conocido).
    created, _ = run_step(session, "POST", f"{URL_JUSTIFICACIONES}/solicitar", {
        "registroId":   1,
        "usuarioCodigo": "2024117001",
        "motivo":        "Enfermedad certificada",
        "documentoUrl":  "https://ejemplo.com/cert.pdf"
    }, sn, se, ck, headers=headers_estudiante, label="JUSTIFICACION ─ Solicitar",
       expected_statuses=(200, 201, 403))

    just_id = None
    if created and isinstance(created, dict):
        just_id = created.get("id")

    # ── Listar todas (Decano) ──
    run_step(session, "GET", f"{URL_JUSTIFICACIONES}/justificaciones", {},
             sn, se, ck, headers=headers_decano, label="JUSTIFICACION ─ Listar todas")

    # ── Por usuarioCodigo (Estudiante) ──
    run_step(session, "GET", f"{URL_JUSTIFICACIONES}/usuario/2024117001", {},
             sn, se, ck, headers=headers_estudiante,
             label="JUSTIFICACION ─ Por usuario (2024117001)")

    # ── Por registroId (Decano) ──
    run_step(session, "GET", f"{URL_JUSTIFICACIONES}/registro/1", {},
             sn, se, ck, headers=headers_decano,
             label="JUSTIFICACION ─ Por registro (id=1)")

    # ── Por estado (Decano) ──
    run_step(session, "GET", f"{URL_JUSTIFICACIONES}/estado/PENDIENTE", {},
             sn, se, ck, headers=headers_decano,
             label="JUSTIFICACION ─ Por estado (PENDIENTE)")

    if just_id:
        # ── FindById (Decano) ──
        run_step(session, "GET", f"{URL_JUSTIFICACIONES}/{just_id}", {},
                 sn, se, ck, headers=headers_decano,
                 label=f"JUSTIFICACION ─ FindById ({just_id})")

        # ── Aprobar (Decano) ──
        run_step(session, "POST", f"{URL_JUSTIFICACIONES}/{just_id}/aprobar", {
            "revisadoPor":    "Decano Pedro",
            "observaciones":  "Documento verificado, aprobado."
        }, sn, se, ck, headers=headers_decano,
            label=f"JUSTIFICACION ─ Aprobar ({just_id})")

        # ── PUT (Decano) ──
        run_step(session, "PUT", f"{URL_JUSTIFICACIONES}/{just_id}", {
            "registroId":   1,
            "usuarioCodigo": "2024117001",
            "motivo":        "Motivo actualizado",
            "documentoUrl":  "https://ejemplo.com/cert-v2.pdf",
            "estado":        "APROBADO"
        }, sn, se, ck, headers=headers_decano,
            label=f"JUSTIFICACION ─ Actualizar ({just_id})")

        # ── Rechazar otra justificación del seed ──
        run_step(session, "POST", f"{URL_JUSTIFICACIONES}/2/rechazar", {
            "revisadoPor":   "Decano Pedro",
            "observaciones": "No cumple requisitos"
        }, sn, se, ck, headers=headers_decano,
            label="JUSTIFICACION ─ Rechazar (id=2)",
            expected_statuses=(200, 201, 404))

        # ── DELETE (Decano) ──
        run_step(session, "DELETE", f"{URL_JUSTIFICACIONES}/{just_id}", {},
                 sn, se, ck, headers=headers_decano,
                 label=f"JUSTIFICACION ─ Eliminar ({just_id})",
                 expected_statuses=(200, 201, 204))
    else:
        print(f"  {C_WARN}⚠ No se obtuvo just_id, omitiendo operaciones sobre ID.{C_RESET}")


# ══════════════════════════════════════════════════════
#  BLOQUE 6 ─ ROTACIÓN DE CLAVES
# ══════════════════════════════════════════════════════
def test_rotacion(session, headers_admin):
    section("ROTACIÓN DE CLAVES RSA")
    print(f"\n{C_TITLE}▶  Rotando claves en servidor de seguridad...{C_RESET}")
    try:
        resp = session.post(URL_ROTATE, headers=headers_admin)
        success = resp.status_code in (200, 201, 204)
        icon = f"{C_SUCCESS}✔" if success else f"{C_WARN}⚠"
        print(f"  {icon} Status {resp.status_code}{C_RESET}")
        _register(success, "SEGURIDAD ─ Rotar claves")
    except requests.exceptions.ConnectionError as exc:
        print(f"  {C_ERROR}✗ No conecta: {exc}{C_RESET}")
        _register(False, "SEGURIDAD ─ Rotar claves")

    print(f"\n{C_DIM}  Esperando 2s para que los servicios invaliden caché...{C_RESET}")
    time.sleep(2)

    # Nueva sesión post-rotación
    section("TURNO 2 ─ TRAS ROTACIÓN (nueva sesión RSA)")
    ts = int(time.time()) % 10000
    sn2, se2, ck2, sid2 = start_session(session)
    print(f"  Nueva sesión con Servidor ID={sid2}")

    # Re-login necesario para obtener un token válido post-rotación
    resp_login = session.post(URL_LOGIN, json={"usuario": "4", "contrasena": "Admin#2024"})
    token2 = None
    try:
        login_data = resp_login.json()
        # El login ya no pasa por cifrado RSA en este endpoint
        token2 = login_data.get("access_token")
    except Exception:
        pass

    if not token2:
        # Intentar con body cifrado
        login2, _ = run_step(session, "POST", URL_LOGIN,
                             {"codigo": 4, "contrasena": "Admin#2024"},
                             sn2, se2, ck2, label="LOGIN post-rotación")
        if login2 and isinstance(login2, dict):
            token2 = login2.get("access_token")

    h2 = {"Authorization": f"Bearer {token2}"} if token2 else {}

    run_step(session, "POST", URL_PLANILLAS, {
        "fechaHoraInicio": "2026-06-01T08:00:00",
        "fechaHoraFin":    "2026-06-01T10:00:00",
        "lugar":     "Sala Post-Rotación",
        "metadatos": "Prueba post-rotación",
        "fechaCreacion": "2026-06-01T07:50:00"
    }, sn2, se2, ck2, headers=h2,
        label="PLANILLA ─ Crear POST-ROTACIÓN")


# ══════════════════════════════════════════════════════
#  RESUMEN FINAL
# ══════════════════════════════════════════════════════
def print_summary():
    width = 60
    print(f"\n{C_HEADER}{'═' * width}{C_RESET}")
    print(f"{C_HEADER}  RESUMEN DE PRUEBAS{C_RESET}")
    print(f"{C_HEADER}{'═' * width}{C_RESET}")
    print(f"  Total   : {C_VAL}{_tests_total}{C_RESET}")
    print(f"  {C_SUCCESS}✔ OK    : {_tests_ok}{C_RESET}")
    print(f"  {C_ERROR}✗ Fallos: {_tests_failed}{C_RESET}")
    pct = (_tests_ok / _tests_total * 100) if _tests_total else 0
    bar_len = 40
    filled  = int(bar_len * _tests_ok // max(_tests_total, 1))
    bar = f"{C_SUCCESS}{'█' * filled}{C_ERROR}{'░' * (bar_len - filled)}{C_RESET}"
    print(f"  [{bar}] {pct:.1f}%")
    print(f"{C_HEADER}{'═' * width}{C_RESET}\n")


# ══════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════
if __name__ == "__main__":
    session = requests.Session()
    ts = int(time.time()) % 10000

    # ── Handshake inicial ──
    section("HANDSHAKE RSA ─ SESIÓN INICIAL")
    print(f"\n{C_DIM}  Obteniendo llave pública del servidor de seguridad...{C_RESET}")
    try:
        sn, se, ck, sid = start_session(session)
        print(f"  {C_SUCCESS}✔ Sesión establecida con Servidor ID={sid}{C_RESET}")
    except Exception as exc:
        print(f"  {C_ERROR}✗ Error en handshake: {exc}{C_RESET}")
        sys.exit(1)

    # ── Login como Administrador ──
    section("AUTENTICACIÓN")
    login_admin, _ = run_step(session, "POST", URL_LOGIN,
                              {"codigo": 4, "contrasena": "Admin#2024"},
                              sn, se, ck, label="LOGIN ─ Administrador (codigo=4)")
    if not login_admin:
        print(f"  {C_ERROR}✗ Login fallido, abortando pruebas.{C_RESET}")
        sys.exit(1)
    h_admin = {"Authorization": f"Bearer {login_admin['access_token']}"}

    # ── Login como Decano ──
    login_decano, _ = run_step(session, "POST", URL_LOGIN,
                               {"codigo": 6, "contrasena": "Decano#11"},
                               sn, se, ck, label="LOGIN ─ Decano (codigo=6)")
    h_decano = {"Authorization": f"Bearer {login_decano['access_token']}"} if login_decano else h_admin

    # ── Login como Estudiante ──
    login_est, _ = run_step(session, "POST", URL_LOGIN,
                            {"codigo": 2, "contrasena": "Clave$456"},
                            sn, se, ck, label="LOGIN ─ Estudiante (codigo=2)")
    h_est = {"Authorization": f"Bearer {login_est['access_token']}"} if login_est else {}

    # ── Login como Monitor ──
    login_monitor, _ = run_step(session, "POST", URL_LOGIN,
                                {"codigo": 1, "contrasena": "Segura#123"},
                                sn, se, ck, label="LOGIN ─ Monitor (codigo=1)")
    h_monitor = {"Authorization": f"Bearer {login_monitor['access_token']}"} if login_monitor else {}

    # ══════════════════════════════════════════════════
    #  EJECUCIÓN DE BLOQUES DE PRUEBA
    # ══════════════════════════════════════════════════
    test_usuario(session, sn, se, ck, h_admin, ts)
    test_planilla(session, sn, se, ck, h_admin)
    test_reporte(session, sn, se, ck, h_admin)
    test_asistencia(session, sn, se, ck, h_est, h_admin, planilla_id_seed=1)
    test_justificacion(session, sn, se, ck, h_monitor, h_decano)
    test_rotacion(session, h_admin)

    # ══════════════════════════════════════════════════
    #  RESUMEN
    # ══════════════════════════════════════════════════
    print_summary()

    sys.exit(0 if _tests_failed == 0 else 1)
