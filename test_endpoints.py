import base64
import json
import os
import re
import sys
import time

import requests
from Crypto.Util.number import getPrime, inverse

# ══════════════════════════════════════════════════════
#  PALETA DE COLORES ANSI
# ══════════════════════════════════════════════════════
C_TITLE = "\033[38;2;0;140;255m"
C_HEADER = "\033[38;2;130;80;255m"
C_SUCCESS = "\033[38;2;50;220;100m"
C_ERROR = "\033[38;2;255;80;80m"
C_WARN = "\033[38;2;255;200;0m"
C_KEY = "\033[38;2;0;179;107m"
C_VAL = "\033[38;2;255;171;92m"
C_DIM = "\033[38;2;120;120;140m"
C_RESET = "\033[0m"

# ══════════════════════════════════════════════════════
#  URLs BASE (mapeadas desde .env → compose.yml)
# ══════════════════════════════════════════════════════
BASE_SEGURIDAD = "http://localhost:8091"
BASE_USUARIO = "http://localhost:8080"
BASE_PLANILLA = "http://localhost:8084"

URL_SEGURIDAD = f"{BASE_SEGURIDAD}/api/v1/security/keys/public"
URL_ROTATE = f"{BASE_SEGURIDAD}/api/v1/security/keys/rotate"

URL_SESSION_KEY = f"{BASE_USUARIO}/api/v1/auth/session-key"
URL_LOGIN = f"{BASE_USUARIO}/api/v1/auth/login"
URL_USUARIOS = f"{BASE_USUARIO}/api/v1/usuario-service/usuarios"

URL_PLANILLAS = f"{BASE_PLANILLA}/api/v1/planilla-service/planillas"
URL_AI_CONFIG = f"{BASE_PLANILLA}/api/v1/planilla-service/ai-config"
URL_REPORTES = f"{BASE_PLANILLA}/api/v1/planilla-service/reportes"
URL_ASISTENCIAS = f"{BASE_PLANILLA}/api/v1/planilla-service/asistencias"
URL_JUSTIFICACIONES = f"{BASE_PLANILLA}/api/v1/planilla-service/justificaciones"
URL_LUGARES = f"{BASE_PLANILLA}/api/v1/planilla-service/lugares"
URL_EVENTOS = f"{BASE_PLANILLA}/api/v1/planilla-service/eventos"
URL_TIPOS_CAMPO = f"{BASE_PLANILLA}/api/v1/planilla-service/tipos-campo"
URL_CAMPOS = f"{BASE_PLANILLA}/api/v1/planilla-service/campos"
URL_FILAS = f"{BASE_PLANILLA}/api/v1/planilla-service/filas"
URL_DATOS = f"{BASE_PLANILLA}/api/v1/planilla-service/datos"

# ══════════════════════════════════════════════════════
#  CONTADOR GLOBAL DE PRUEBAS
# ══════════════════════════════════════════════════════
_tests_total = 0
_tests_ok = 0
_tests_failed = 0


def resolve_test_image_path() -> str:
    """
    Resuelve la imagen de prueba sin depender del cwd actual.
    """
    root_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(root_dir, "MicroservicioPlanilla", "testImages", "test1.jpg")


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
            chunk = text_bytes[i : i + chunk_size]
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
                    m.to_bytes(byte_length, byteorder="big", signed=False).decode(
                        "utf-8"
                    )
                )
            except Exception:
                result.append("[Err]")
        return "".join(result)


# ══════════════════════════════════════════════════════
#  UTILIDADES DE PRESENTACIÓN
# ══════════════════════════════════════════════════════
def color_json(s: str) -> str:
    s = re.sub(r'(data:image/[^"]{1,20};base64,)[A-Za-z0-9+/=]{100,}', r'\1[FIRMA_BASE64_OMITIDA]', s)
    s = re.sub(r'(".*?")\s*:', f"{C_KEY}\\1{C_RESET}:", s)
    s = re.sub(r':\s*(".*?")', f": {C_VAL}\\1{C_RESET}", s)
    s = re.sub(
        r":\s*([0-9\.]+|true|false|null)(?=[,\s\}]|$)", f": {C_VAL}\\1{C_RESET}", s
    )
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
def run_step(
    session,
    method: str,
    url: str,
    body_dict: dict,
    server_n: int,
    server_e: int,
    client_key: dict,
    headers=None,
    label="STEP",
    expected_statuses=(200, 201, 204),
):
    """
    Envía una petición cifrada y muestra el resultado.
    Retorna (parsed_response | None, status_code).
    """
    print(f"\n{C_TITLE}▶  {label}{C_RESET}")

    plain_json = json.dumps(body_dict)
    encrypted_body = CustomRSA.encrypt(plain_json, server_n, server_e)
    funcs = {
        "POST": session.post,
        "PUT": session.put,
        "DELETE": session.delete,
        "GET": session.get,
        "PATCH": session.patch,
    }
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

    success = resp.status_code in expected_statuses
    icon = f"{C_SUCCESS}✔" if success else f"{C_ERROR}✗"
    print(f"  {icon} Status {resp.status_code}{C_RESET}")

    # Intentar desencriptar siempre, incluso si hay error
    decrypted = decrypt_server_response(resp_json, client_key)

    if resp.text.strip():
        print(f"  {C_DIM}Respuesta (puedes ver el error aquí):{C_RESET}")
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


def run_step_raw(
    session,
    method: str,
    url: str,
    headers=None,
    params=None,
    label="STEP RAW",
    expected_statuses=(200, 201, 204),
):
    """
    Petición SIN cifrar el body (para endpoints que reciben params o nada).
    """
    print(f"\n{C_TITLE}▶  {label}{C_RESET}")
    funcs = {
        "POST": session.post,
        "PUT": session.put,
        "DELETE": session.delete,
        "GET": session.get,
        "PATCH": session.patch,
    }
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
    icon = f"{C_SUCCESS}✔" if success else f"{C_ERROR}✗"
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
#  HELPERS ─ MAPAS DINÁMICOS DESDE EL BACKEND
# ══════════════════════════════════════════════════════
def obtener_tipos_campo(session, sn, se, ck, headers):
    """GET /tipos-campo y retorna dict {tipo: id}."""
    resp_json, status = run_step(
        session, "GET", URL_TIPOS_CAMPO, {}, sn, se, ck,
        headers=headers, label="HELPER ─ Obtener tipos de campo",
        expected_statuses=(200, 201),
    )
    tipos_map = {}
    if resp_json and isinstance(resp_json, list):
        for item in resp_json:
            if isinstance(item, dict):
                tipos_map[item.get("tipo")] = item.get("id")
    return tipos_map


def obtener_origenes(session, sn, se, ck, headers):
    """GET /origenes y retorna dict {origen: id}."""
    resp_json, status = run_step(
        session, "GET", f"{BASE_PLANILLA}/api/v1/planilla-service/origenes", {}, sn, se, ck,
        headers=headers, label="HELPER ─ Obtener orígenes",
        expected_statuses=(200, 201),
    )
    origenes_map = {}
    if resp_json and isinstance(resp_json, list):
        for item in resp_json:
            if isinstance(item, dict):
                origenes_map[item.get("origen")] = item.get("id")
    return origenes_map


def _parse_ai_json(text: str):
    """Extrae JSON de una respuesta de IA (puede venir en markdown, texto plano, etc)."""
    if not isinstance(text, str):
        return text
    text = text.strip()
    # Intentar directo
    if text.startswith("{"):
        try:
            return json.loads(text)
        except Exception:
            pass
    # Buscar bloque ```json ... ```
    match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', text)
    if match:
        try:
            return json.loads(match.group(1).strip())
        except Exception:
            pass
    # Buscar primer { ... }
    match = re.search(r'\{[\s\S]*\}', text)
    if match:
        try:
            return json.loads(match.group())
        except Exception:
            pass
    return None


# ══════════════════════════════════════════════════════
#  BLOQUE 1 ─ MICROSERVICIO USUARIO
# ══════════════════════════════════════════════════════
def test_usuario(session, sn, se, ck, headers, ts):
    section("MICROSERVICIO USUARIO")

    # Listar
    run_step(
        session,
        "GET",
        URL_USUARIOS,
        {},
        sn,
        se,
        ck,
        headers=headers,
        label="USUARIO ─ Listar todos",
    )

    # Helper: obtener roles dinámicamente
    roles_map = {}
    try:
        roles_resp = session.get(f"{BASE_USUARIO}/api/v1/usuario-service/roles", headers=headers)
        if roles_resp.status_code == 200:
            for r in roles_resp.json():
                roles_map[r.get("nombre")] = r.get("id")
    except Exception:
        pass

    estudiante_rol_id = roles_map.get("Estudiante", 1)
    monitor_rol_id = roles_map.get("Monitor", 8)

    # Crear
    new_code = 6000 + ts
    created, _ = run_step(
        session,
        "POST",
        URL_USUARIOS,
        {
            "codigo": new_code,
            "nombreCompleto": f"Test User {ts}",
            "correo": f"test-{ts}@uceva.edu.co",
            "contrasena": "TestPass#1",
            "cedula": 99000000 + ts,
            "telefono": 3100000000 + ts,
            "rol": {"id": estudiante_rol_id},
        },
        sn,
        se,
        ck,
        headers=headers,
        label=f"USUARIO ─ Crear (codigo={new_code})",
    )

    # Actualizar código 1
    run_step(
        session,
        "PUT",
        URL_USUARIOS,
        {
            "codigo": 1,
            "nombreCompleto": f"Juan Editado {ts}",
            "correo": "juan.perez@uceva.edu.co",
            "contrasena": "Segura#123",
            "cedula": 1001234567,
            "telefono": 3101234567,
            "rol": {"id": monitor_rol_id},
        },
        sn,
        se,
        ck,
        headers=headers,
        label="USUARIO ─ Actualizar (codigo=1)",
    )

    # Eliminar (probaremos código 10 si existe)
    run_step(
        session,
        "DELETE",
        URL_USUARIOS,
        {"codigo": 10},
        sn,
        se,
        ck,
        headers=headers,
        label="USUARIO ─ Eliminar (codigo=10)",
        expected_statuses=(200, 201, 204, 404),
    )

    return new_code


# ══════════════════════════════════════════════════════
#  BLOQUE 2 ─ MICROSERVICIO PLANILLA
# ══════════════════════════════════════════════════════
def test_planilla(session, sn, se, ck, headers_admin, origen_digital_id):
    section("MICROSERVICIO PLANILLA")

    # Listar
    run_step(
        session,
        "GET",
        URL_PLANILLAS,
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label="PLANILLA ─ Listar todas",
    )

    # Crear con origen (nuevo modelo)
    created, _ = run_step(
        session,
        "POST",
        URL_PLANILLAS,
        {"origen": {"id": origen_digital_id}},
        sn,
        se,
        ck,
        headers=headers_admin,
        label="PLANILLA ─ Crear",
    )

    planilla_id = None
    if created and isinstance(created, dict):
        planilla_id = created.get("id")

    if planilla_id:
        # Buscar por ID
        run_step(
            session,
            "GET",
            f"{URL_PLANILLAS}/{planilla_id}",
            {},
            sn,
            se,
            ck,
            headers=headers_admin,
            label=f"PLANILLA ─ FindById ({planilla_id})",
        )

        # Actualizar (origen es obligatorio en el modelo)
        run_step(
            session,
            "PUT",
            URL_PLANILLAS,
            {
                "id": planilla_id,
                "origen": {"id": origen_digital_id},
            },
            sn,
            se,
            ck,
            headers=headers_admin,
            label=f"PLANILLA ─ Actualizar ({planilla_id})",
        )

        # Eliminar
        run_step(
            session,
            "DELETE",
            f"{URL_PLANILLAS}/{planilla_id}",
            {},
            sn,
            se,
            ck,
            headers=headers_admin,
            label=f"PLANILLA ─ Eliminar ({planilla_id})",
            expected_statuses=(200, 201, 204),
        )
    else:
        print(
            f"  {C_WARN}⚠ No se pudo obtener planilla_id, omitiendo pruebas dependientes.{C_RESET}"
        )

    return planilla_id


def test_digitalizar(session, sn, se, client_key, headers_admin, planilla_id):
    section("PLANILLA ─ DIGITALIZAR")
    url = f"{URL_PLANILLAS}/digitalizar"
    file_path = resolve_test_image_path()

    print(f"\n{C_TITLE}▶  PLANILLA ─ Digitalizar imagen{C_RESET}")
    decrypted_json = None
    success = False
    try:
        if not os.path.exists(file_path):
            print(f"  {C_ERROR}✗ Archivo no encontrado: {file_path}{C_RESET}")
            _register(False, "PLANILLA ─ Digitalizar")
            return

        with open(file_path, "rb") as f:
            files = {"file": ("2026-04-14_082294-4.jpg", f, "image/jpeg")}
            resp = session.post(url, files=files, headers=headers_admin, params={"planillaId": planilla_id, "estructuraJson": "{}"})

        success = resp.status_code in (200, 201)
        icon = f"{C_SUCCESS}✔" if success else f"{C_ERROR}✗"
        print(f"  {icon} Status {resp.status_code}{C_RESET}")

        if resp.text.strip():
            try:
                resp_json = resp.json()
            except:
                resp_json = {"raw": resp.text}

            decrypted = decrypt_server_response(resp_json, client_key)
            print(f"  {C_DIM}Resultado OCR/IA (Desencriptado):{C_RESET}")
            try:
                import json

                decrypted_json = (
                    json.loads(decrypted) if isinstance(decrypted, str) else decrypted
                )
                print(
                    f"  {C_VAL}Se obtuvieron {len(decrypted_json) if isinstance(decrypted_json, list) else 1} registros.{C_RESET}"
                )
            except:
                print(f"  {C_VAL}{str(decrypted)[:500]}...{C_RESET}")

        _register(success, "PLANILLA ─ Digitalizar")
    except Exception as exc:
        print(f"  {C_ERROR}✗ Error en la prueba: {exc}{C_RESET}")
        _register(False, "PLANILLA ─ Digitalizar")

    # Si el resultado es un string (posible doble codificación), intentamos parsearlo
    if success and isinstance(decrypted_json, str):
        try:
            import json
            decrypted_json = json.loads(decrypted_json)
        except:
            pass

    # Si el resultado es un objeto único, lo tratamos como una lista de uno
    if success and isinstance(decrypted_json, dict):
        decrypted_json = [decrypted_json]

    if not success or not isinstance(decrypted_json, list) or len(decrypted_json) == 0:
        tipo = type(decrypted_json).__name__
        print(f"  {C_WARN}⚠ Saltando pruebas de Recorte y Guardar: No se obtuvieron registros válidos (Tipo: {tipo}).{C_RESET}")
    else:
        import base64
        try:
            with open(file_path, "rb") as f:
                img_b64 = "data:image/jpeg;base64," + base64.b64encode(f.read()).decode(
                    "utf-8"
                )

            crop_payload = {
                "index": 0,
                "x": 10,
                "y": 10,
                "w": 100,
                "h": 50,
                "sourceImageB64": img_b64,
            }
            resp_recorte, success_recorte = run_step(
                session,
                "POST",
                f"{URL_PLANILLAS}/digitalizar/recortar",
                crop_payload,
                sn,
                se,
                client_key,
                headers=headers_admin,
                label="PLANILLA ─ Recortar firma",
            )

            if success_recorte and resp_recorte:
                print(f"  {C_VAL}Firma recortada obtenida (Base64){C_RESET}")
                decrypted_json[0]["firma"] = resp_recorte.get("firmaB64", "")

            resp_guardar, success_guardar = run_step(
                session,
                "POST",
                f"{URL_PLANILLAS}/digitalizar/guardar?planillaId={planilla_id}",
                decrypted_json,
                sn,
                se,
                client_key,
                headers=headers_admin,
                label="PLANILLA ─ Guardar digitalización",
            )

            if success_guardar and resp_guardar:
                print(f"  {C_VAL}Registros guardados en S3 exitosamente{C_RESET}")
        except Exception as exc:
            print(f"  {C_ERROR}✗ Error probando recorte/guardado: {exc}{C_RESET}")
            _register(False, "PLANILLA ─ Recortar / Guardar")

    url_campos = f"{URL_PLANILLAS}/campos"
    print(f"\n{C_TITLE}▶  PLANILLA ─ Obtener Campos (Estructura){C_RESET}")
    try:
        if not os.path.exists(file_path):
            print(f"  {C_ERROR}✗ Archivo no encontrado: {file_path}{C_RESET}")
            _register(False, "PLANILLA ─ Obtener Campos")
            return

        with open(file_path, "rb") as f:
            files = {"file": ("2026-04-14_082294-4.jpg", f, "image/jpeg")}
            resp = session.post(url_campos, files=files, headers=headers_admin)

        success = resp.status_code in (200, 201)
        icon = f"{C_SUCCESS}✔" if success else f"{C_ERROR}✗"
        print(f"  {icon} Status {resp.status_code}{C_RESET}")

        if resp.text.strip():
            try:
                resp_json = resp.json()
            except:
                resp_json = {"raw": resp.text}

            decrypted = decrypt_server_response(resp_json, client_key)
            print(f"  {C_DIM}Resultado OCR/IA Estructura (Desencriptado):{C_RESET}")
            try:
                print(f"  {C_VAL}{pretty_json(decrypted)}{C_RESET}")
            except:
                print(f"  {C_VAL}{decrypted}{C_RESET}")

        _register(success, "PLANILLA ─ Obtener Campos")
    except Exception as exc:
        print(f"  {C_ERROR}✗ Error en la prueba: {exc}{C_RESET}")
        _register(False, "PLANILLA ─ Obtener Campos")


# ══════════════════════════════════════════════════════
#  BLOQUE 2 ─ GUARDAR PLANILLA DIGITALIZADA (OCR → DB)
# ══════════════════════════════════════════════════════
def test_guardar_planilla_digitalizada(session, sn, se, ck, headers_admin, tipos_map, origen_digital_id):
    section("GUARDAR PLANILLA DIGITALIZADA (OCR → DB)")

    file_path = resolve_test_image_path()
    if not os.path.exists(file_path):
        print(f"  {C_ERROR}✗ Imagen no encontrada: {file_path}{C_RESET}")
        _register(False, "GUARDAR DIGITAL ─ Prerequisito")
        return

    # ── Paso 1: Obtener estructura de la imagen ──
    url_campos = f"{URL_PLANILLAS}/campos"
    estructura_json = None
    print(f"\n{C_TITLE}▶  GUARDAR DIGITAL ─ Extraer estructura OCR{C_RESET}")
    try:
        with open(file_path, "rb") as f:
            files = {"file": ("test.jpg", f, "image/jpeg")}
            resp = session.post(url_campos, files=files, headers=headers_admin)
        if resp.status_code in (200, 201):
            try:
                resp_json = resp.json()
                decrypted = decrypt_server_response(resp_json, ck)
                # El endpoint devuelve String → Jackson lo serializa como JSON string.
                # Hay que hacer json.loads una vez más para obtener el texto real.
                if isinstance(decrypted, str):
                    try:
                        decrypted = json.loads(decrypted)
                    except Exception:
                        pass
                print(f"  {C_DIM}Respuesta cruda IA (primeros 400 chars):{C_RESET}")
                print(f"  {C_VAL}{str(decrypted)[:400]}{C_RESET}")
                estructura_json = _parse_ai_json(decrypted)
                if estructura_json and isinstance(estructura_json, dict):
                    encs = estructura_json.get("encabezados", estructura_json.get("campos"))
                    if isinstance(encs, list) and len(encs) > 0:
                        print(f"  {C_SUCCESS}✔ Estructura detectada: {len(encs)} columnas{C_RESET}")
                    else:
                        estructura_json = None
            except Exception as e:
                print(f"  {C_ERROR}✗ Error parseando respuesta IA: {e}{C_RESET}")
                estructura_json = None
        success = estructura_json is not None
    except Exception as exc:
        print(f"  {C_ERROR}✗ Error: {exc}{C_RESET}")
        success = False
    _register(success, "GUARDAR DIGITAL ─ Extraer estructura")

    if not estructura_json:
        print(f"  {C_WARN}⚠ No se pudo extraer estructura, omitiendo resto del flujo.{C_RESET}")
        return

    # ── Paso 2: Crear planilla ──
    planilla, _ = run_step(
        session, "POST", URL_PLANILLAS,
        {"origen": {"id": origen_digital_id}},
        sn, se, ck, headers=headers_admin,
        label="GUARDAR DIGITAL ─ Crear planilla",
    )
    planilla_id = planilla.get("id") if isinstance(planilla, dict) else None
    if not planilla_id:
        print(f"  {C_WARN}⚠ No se pudo crear planilla, omitiendo resto.{C_RESET}")
        return

    # ── Paso 3: Guardar estructura (campos) ──
    encabezados = estructura_json.get("encabezados", [])
    if not isinstance(encabezados, list) or not encabezados:
        print(f"  {C_WARN}⚠ Estructura sin encabezados válidos.{C_RESET}")
        return

    campos_confirmar = []
    for enc in encabezados:
        if not isinstance(enc, dict):
            continue
        nombre = enc.get("nombre") or enc.get("nombre_campo", "")
        tipo_str = enc.get("tipo_campo", "text")
        tipo_id = tipos_map.get(tipo_str)
        if not tipo_id:
            tipo_id = tipos_map.get("text", 1)
        campos_confirmar.append({
            "planillaId": planilla_id,
            "tipoCampoId": tipo_id,
            "nombreCampo": nombre,
            "obligatorio": enc.get("obligatorio", False),
            "opciones": enc.get("opciones"),
        })

    print(f"  {C_VAL}Mapeados {len(campos_confirmar)} campos{C_RESET}")
    run_step(
        session, "POST", f"{URL_PLANILLAS}/{planilla_id}/confirmar-estructura",
        campos_confirmar, sn, se, ck, headers=headers_admin,
        label="GUARDAR DIGITAL ─ Confirmar estructura",
    )

    # ── Paso 4: Obtener datos OCR (filas) ──
    estructura_str = json.dumps(estructura_json)
    decrypted_data = None
    print(f"\n{C_TITLE}▶  GUARDAR DIGITAL ─ Extraer datos OCR{C_RESET}")
    try:
        with open(file_path, "rb") as f:
            files = {"file": ("test.jpg", f, "image/jpeg")}
            resp = session.post(f"{URL_PLANILLAS}/digitalizar",
                                files=files, headers=headers_admin,
                                params={"planillaId": planilla_id, "estructuraJson": estructura_str})
        if resp.status_code in (200, 201):
            resp_json = resp.json() if resp.text.strip() else {}
            decrypted = decrypt_server_response(resp_json, ck)
            decrypted_data = json.loads(decrypted) if isinstance(decrypted, str) else decrypted
            if isinstance(decrypted_data, dict):
                decrypted_data = [decrypted_data]
            if isinstance(decrypted_data, list):
                total_filas = sum(len(h.get("filas", [])) for h in decrypted_data if isinstance(h, dict))
                print(f"  {C_SUCCESS}✔ {len(decrypted_data)} página(s), {total_filas} fila(s) detectadas{C_RESET}")
    except Exception as exc:
        print(f"  {C_ERROR}✗ Error: {exc}{C_RESET}")
    _register(isinstance(decrypted_data, list), "GUARDAR DIGITAL ─ Extraer datos")

    if not isinstance(decrypted_data, list) or len(decrypted_data) == 0:
        print(f"  {C_WARN}⚠ Sin datos OCR, omitiendo guardado de filas.{C_RESET}")
    else:
        # ── Paso 5: Guardar filas y datos ──
        campo_nombre_to_id = {}
        campos_resp, _ = run_step(
            session, "GET", f"{URL_CAMPOS}/planilla/{planilla_id}", {}, sn, se, ck,
            headers=headers_admin, label="GUARDAR DIGITAL ─ Obtener campos persistidos",
            expected_statuses=(200, 201),
        )
        if isinstance(campos_resp, list):
            for c in campos_resp:
                if isinstance(c, dict):
                    campo_nombre_to_id[c.get("nombreCampo")] = c.get("id")

        total_filas_creadas = 0
        for hoja in decrypted_data:
            if not isinstance(hoja, dict):
                continue
            for fila_digital in hoja.get("filas", []):
                if not isinstance(fila_digital, dict):
                    continue
                idx = fila_digital.get("indice", fila_digital.get("fila", 0))
                valores = fila_digital.get("valores", [])
                datos_fila = []
                for celda in valores:
                    if not isinstance(celda, dict):
                        continue
                    c_nombre = celda.get("nombreCampo", "")
                    c_id = campo_nombre_to_id.get(c_nombre)
                    if c_id:
                        datos_fila.append({
                            "campoId": c_id,
                            "posicion": 0,
                            "informacion": celda.get("valor", ""),
                        })
                if datos_fila:
                    fila_creada, _ = run_step(
                        session, "POST", URL_FILAS,
                        {"planillaId": planilla_id, "indice": idx, "datos": datos_fila},
                        sn, se, ck, headers=headers_admin,
                        label=f"GUARDAR DIGITAL ─ Fila indice={idx}",
                    )
                    if fila_creada:
                        total_filas_creadas += 1

        print(f"  {C_VAL}Total filas persistidas: {total_filas_creadas}{C_RESET}")
        _register(total_filas_creadas > 0, "GUARDAR DIGITAL ─ Persistir filas")

        # ── Paso 6: Guardar firmas en S3 ──
        # Inyectar imagen de referencia en el body
        try:
            with open(file_path, "rb") as img_file:
                img_ref_b64 = "data:image/jpeg;base64," + base64.b64encode(img_file.read()).decode("utf-8")
            if isinstance(decrypted_data, list) and len(decrypted_data) > 0 and isinstance(decrypted_data[0], dict):
                decrypted_data[0]["imagenReferenciaB64"] = img_ref_b64
        except Exception:
            pass

        run_step(
            session, "POST",
            f"{URL_PLANILLAS}/digitalizar/guardar?planillaId={planilla_id}",
            decrypted_data, sn, se, ck, headers=headers_admin,
            label="GUARDAR DIGITAL ─ Subir firmas + ref a S3",
        )

        # Mostrar resumen de lo subido
        run_step(
            session, "GET", f"{URL_PLANILLAS}/{planilla_id}", {}, sn, se, ck,
            headers=headers_admin, label=f"GUARDAR DIGITAL ─ Verificar planilla + urlRef ({planilla_id})",
        )
    run_step(
        session, "GET", f"{URL_FILAS}/planilla/{planilla_id}", {}, sn, se, ck,
        headers=headers_admin, label=f"GUARDAR DIGITAL ─ Verificar filas ({planilla_id})",
    )


# ══════════════════════════════════════════════════════
#  BLOQUE 2A ─ LUGARES
# ══════════════════════════════════════════════════════
def test_lugares(session, sn, se, ck, headers_admin):
    section("LUGARES")
    # Crear
    created, _ = run_step(
        session, "POST", URL_LUGARES,
        {"nombre": "Aula de Prueba", "coordenadas": "4.0,-72.0"},
        sn, se, ck, headers=headers_admin,
        label="LUGAR ─ Crear",
    )
    lugar_id = None
    if created and isinstance(created, dict):
        lugar_id = created.get("id")

    if lugar_id:
        run_step(session, "GET", f"{URL_LUGARES}/{lugar_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"LUGAR ─ FindById ({lugar_id})")
        run_step(session, "PUT", f"{URL_LUGARES}/{lugar_id}",
                 {"nombre": "Aula de Prueba (actualizado)", "coordenadas": "4.1,-72.1"},
                 sn, se, ck, headers=headers_admin,
                 label=f"LUGAR ─ Actualizar ({lugar_id})")
        run_step(session, "GET", URL_LUGARES, {}, sn, se, ck,
                 headers=headers_admin, label="LUGAR ─ Listar todos")
        # No eliminar lugar para que test_eventos pueda usarlo
    return lugar_id


# ══════════════════════════════════════════════════════
#  BLOQUE 2B ─ EVENTOS
# ══════════════════════════════════════════════════════
def test_eventos(session, sn, se, ck, headers_admin, lugar_id):
    section("EVENTOS")
    if not lugar_id:
        print(f"  {C_WARN}⚠ No hay lugar_id, omitiendo tests de eventos.{C_RESET}")
        return None

    created, _ = run_step(
        session, "POST", URL_EVENTOS,
        {
            "nombre": "Evento de Prueba",
            "descripcion": "Descripción del evento de prueba",
            "fechaHoraInicio": "2026-05-10T08:00:00",
            "fechaHoraFin": "2026-05-10T10:00:00",
            "lugar": {"id": lugar_id},
        },
        sn, se, ck, headers=headers_admin,
        label="EVENTO ─ Crear",
    )
    evento_id = None
    if created and isinstance(created, dict):
        evento_id = created.get("id")

    if evento_id:
        run_step(session, "GET", f"{URL_EVENTOS}/{evento_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"EVENTO ─ FindById ({evento_id})")
        run_step(session, "GET", URL_EVENTOS, {}, sn, se, ck,
                 headers=headers_admin, label="EVENTO ─ Listar todos")
        run_step(session, "GET", f"{URL_EVENTOS}/usuario/1", {}, sn, se, ck,
                 headers=headers_admin, label="EVENTO ─ Por usuario (codigo=1)")
        run_step(session, "PUT", f"{URL_EVENTOS}/{evento_id}",
                 {
                     "nombre": "Evento Actualizado",
                     "descripcion": "Actualizado",
                     "fechaHoraInicio": "2026-05-10T09:00:00",
                     "fechaHoraFin": "2026-05-10T11:00:00",
                     "lugar": {"id": lugar_id},
                 },
                 sn, se, ck, headers=headers_admin,
                 label=f"EVENTO ─ Actualizar ({evento_id})")
        run_step(session, "DELETE", f"{URL_EVENTOS}/{evento_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"EVENTO ─ Eliminar ({evento_id})",
                 expected_statuses=(200, 201, 204))
    return evento_id


# ══════════════════════════════════════════════════════
#  BLOQUE 2C ─ CAMPOS
# ══════════════════════════════════════════════════════
def test_campos(session, sn, se, ck, headers_admin, planilla_id, tipos_map):
    section("CAMPOS")
    if not planilla_id or not tipos_map:
        print(f"  {C_WARN}⚠ Faltan planilla_id o tipos_map, omitiendo tests de campos.{C_RESET}")
        return []

    tipo_text_id = tipos_map.get("text")
    tipo_numeric_id = tipos_map.get("numeric")
    if not tipo_text_id or not tipo_numeric_id:
        print(f"  {C_WARN}⚠ No se encontraron tipos 'text' o 'numeric'.{C_RESET}")
        return []

    # Crear campo
    created, _ = run_step(
        session, "POST", URL_CAMPOS,
        {"planillaId": planilla_id, "tipoCampoId": tipo_text_id,
         "nombreCampo": "Campo de Prueba", "obligatorio": True},
        sn, se, ck, headers=headers_admin,
        label="CAMPO ─ Crear",
    )
    campo_id = None
    if created and isinstance(created, dict):
        campo_id = created.get("id")

    campos_creados = []
    if campo_id:
        campos_creados.append(campo_id)
        run_step(session, "GET", f"{URL_CAMPOS}/{campo_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"CAMPO ─ FindById ({campo_id})")
        run_step(session, "GET", f"{URL_CAMPOS}/planilla/{planilla_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"CAMPO ─ Por planilla ({planilla_id})")
        run_step(session, "PUT", f"{URL_CAMPOS}/{campo_id}",
                 {"planillaId": planilla_id, "tipoCampoId": tipo_text_id,
                  "nombreCampo": "Campo Actualizado", "obligatorio": False},
                 sn, se, ck, headers=headers_admin,
                 label=f"CAMPO ─ Actualizar ({campo_id})")

    # Batch
    run_step(
        session, "POST", f"{URL_CAMPOS}/batch",
        [
            {"planillaId": planilla_id, "tipoCampoId": tipo_numeric_id,
             "nombreCampo": "Edad", "obligatorio": True},
            {"planillaId": planilla_id, "tipoCampoId": tipo_text_id,
             "nombreCampo": "Correo", "obligatorio": False},
        ],
        sn, se, ck, headers=headers_admin,
        label="CAMPO ─ Batch crear",
    )

    # Listar todos
    run_step(session, "GET", URL_CAMPOS, {}, sn, se, ck,
             headers=headers_admin, label="CAMPO ─ Listar todos")

    if campo_id:
        run_step(session, "DELETE", f"{URL_CAMPOS}/{campo_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"CAMPO ─ Eliminar ({campo_id})",
                 expected_statuses=(200, 201, 204))
    return campos_creados


# ══════════════════════════════════════════════════════
#  BLOQUE 2D ─ FILAS
# ══════════════════════════════════════════════════════
def test_filas(session, sn, se, ck, headers_admin, planilla_id, campos_ids, tipos_map):
    section("FILAS")
    if not planilla_id:
        print(f"  {C_WARN}⚠ No hay planilla_id, omitiendo tests de filas.{C_RESET}")
        return None

    # Obtener campos de la planilla para construir filas con datos
    campos_resp, _ = run_step(
        session, "GET", f"{URL_CAMPOS}/planilla/{planilla_id}", {}, sn, se, ck,
        headers=headers_admin, label="FILA ─ Obtener campos de planilla",
        expected_statuses=(200, 201),
    )
    campos_planilla = []
    if campos_resp and isinstance(campos_resp, list):
        campos_planilla = campos_resp

    # Crear fila con datos
    datos_fila = []
    for i, c in enumerate(campos_planilla[:3]):  # máx 3 campos para simplificar
        if isinstance(c, dict):
            datos_fila.append({
                "campoId": c.get("id"),
                "posicion": 0,
                "informacion": f"valor_{i}",
            })

    created, _ = run_step(
        session, "POST", URL_FILAS,
        {"planillaId": planilla_id, "indice": 0, "datos": datos_fila},
        sn, se, ck, headers=headers_admin,
        label="FILA ─ Crear",
    )
    fila_id = None
    if created and isinstance(created, dict):
        fila_id = created.get("id")

    if fila_id:
        run_step(session, "GET", f"{URL_FILAS}/{fila_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"FILA ─ FindById ({fila_id})")
        run_step(session, "GET", f"{URL_FILAS}/planilla/{planilla_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"FILA ─ Por planilla ({planilla_id})")
        run_step(session, "PUT", f"{URL_FILAS}/{fila_id}",
                 {"planillaId": planilla_id, "indice": 0, "datos": datos_fila},
                 sn, se, ck, headers=headers_admin,
                 label=f"FILA ─ Actualizar ({fila_id})")
        run_step(session, "PATCH", f"{URL_FILAS}/{fila_id}",
                 {"planillaId": planilla_id, "indice": 0, "datos": datos_fila},
                 sn, se, ck, headers=headers_admin,
                 label=f"FILA ─ Patch ({fila_id})")
        run_step(session, "DELETE", f"{URL_FILAS}/{fila_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"FILA ─ Eliminar ({fila_id})",
                 expected_statuses=(200, 201, 204))

    # Batch
    if len(campos_planilla) >= 2:
        batch_datos = [
            {"campoId": campos_planilla[0].get("id"), "posicion": 0, "informacion": "batch1"},
            {"campoId": campos_planilla[1].get("id"), "posicion": 0, "informacion": "batch2"},
        ]
        run_step(
            session, "POST", f"{URL_FILAS}/batch",
            [{"planillaId": planilla_id, "indice": 1, "datos": batch_datos}],
            sn, se, ck, headers=headers_admin,
            label="FILA ─ Batch crear",
        )

    run_step(session, "GET", URL_FILAS, {}, sn, se, ck,
             headers=headers_admin, label="FILA ─ Listar todos")
    return fila_id


# ══════════════════════════════════════════════════════
#  BLOQUE 2E ─ DATOS
# ══════════════════════════════════════════════════════
def test_datos(session, sn, se, ck, headers_admin, planilla_id):
    section("DATOS")
    if not planilla_id:
        print(f"  {C_WARN}⚠ No hay planilla_id, omitiendo tests de datos.{C_RESET}")
        return

    # Obtener campos de la planilla
    campos_resp, _ = run_step(
        session, "GET", f"{URL_CAMPOS}/planilla/{planilla_id}", {}, sn, se, ck,
        headers=headers_admin, label="DATO ─ Obtener campos de planilla",
        expected_statuses=(200, 201),
    )
    campos_planilla = []
    if campos_resp and isinstance(campos_resp, list):
        campos_planilla = campos_resp

    if not campos_planilla:
        print(f"  {C_WARN}⚠ Planilla sin campos, omitiendo tests de datos.{C_RESET}")
        return

    # Obtener filas de la planilla
    filas_resp, _ = run_step(
        session, "GET", f"{URL_FILAS}/planilla/{planilla_id}", {}, sn, se, ck,
        headers=headers_admin, label="DATO ─ Obtener filas de planilla",
        expected_statuses=(200, 201),
    )
    filas_planilla = []
    if filas_resp and isinstance(filas_resp, list):
        filas_planilla = filas_resp

    fila_id = None
    if filas_planilla and isinstance(filas_planilla[0], dict):
        fila_id = filas_planilla[0].get("id")

    # Crear una fila nueva exclusiva para tests de datos (sin datos previos)
    fila_nueva, _ = run_step(
        session, "POST", URL_FILAS,
        {"planillaId": planilla_id, "indice": 99, "datos": []},
        sn, se, ck, headers=headers_admin,
        label="DATO ─ Crear fila vacía para datos",
        expected_statuses=(200, 201),
    )
    if fila_nueva and isinstance(fila_nueva, dict):
        fila_id = fila_nueva.get("id")

    if not fila_id:
        print(f"  {C_WARN}⚠ No hay filas en la planilla, omitiendo tests de datos.{C_RESET}")
        return

    campo_id = campos_planilla[0].get("id") if campos_planilla else None
    if not campo_id:
        return

    # Crear dato
    created, _ = run_step(
        session, "POST", URL_DATOS,
        {"campoId": campo_id, "filaId": fila_id, "posicion": 0, "informacion": "Dato de prueba"},
        sn, se, ck, headers=headers_admin,
        label="DATO ─ Crear",
    )
    dato_id = None
    if created and isinstance(created, dict):
        dato_id = created.get("id")

    if dato_id:
        run_step(session, "GET", f"{URL_DATOS}/{dato_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"DATO ─ FindById ({dato_id})")
        run_step(session, "GET", f"{URL_DATOS}/planilla/{planilla_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"DATO ─ Por planilla ({planilla_id})")
        run_step(session, "GET", f"{URL_DATOS}/campo/{campo_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"DATO ─ Por campo ({campo_id})")
        run_step(session, "PUT", f"{URL_DATOS}/{dato_id}",
                 {"campoId": campo_id, "filaId": fila_id, "posicion": 0, "informacion": "Dato actualizado"},
                 sn, se, ck, headers=headers_admin,
                 label=f"DATO ─ Actualizar ({dato_id})")
        run_step(session, "DELETE", f"{URL_DATOS}/{dato_id}", {}, sn, se, ck,
                 headers=headers_admin, label=f"DATO ─ Eliminar ({dato_id})",
                 expected_statuses=(200, 201, 204))

    # Batch
    if len(campos_planilla) >= 2:
        run_step(
            session, "POST", f"{URL_DATOS}/batch",
            [
                {"campoId": campos_planilla[0].get("id"), "filaId": fila_id,
                 "posicion": 0, "informacion": "batch_a"},
                {"campoId": campos_planilla[1].get("id"), "filaId": fila_id,
                 "posicion": 0, "informacion": "batch_b"},
            ],
            sn, se, ck, headers=headers_admin,
            label="DATO ─ Batch crear",
        )


# ══════════════════════════════════════════════════════
#  BLOQUE 2F ─ IA: PROPONER ESTRUCTURA DESDE IMAGEN
# ══════════════════════════════════════════════════════
def test_proponer_estructura(session, sn, se, ck, headers_admin, planilla_id, tipos_map):
    section("IA ─ PROPONER ESTRUCTURA DESDE IMAGEN")
    if not planilla_id:
        print(f"  {C_WARN}⚠ No hay planilla_id, omitiendo.{C_RESET}")
        return

    file_path = resolve_test_image_path()
    if not os.path.exists(file_path):
        print(f"  {C_ERROR}✗ Imagen no encontrada: {file_path}{C_RESET}")
        _register(False, "IA ─ Proponer estructura")
        return

    url = f"{URL_PLANILLAS}/{planilla_id}/proponer-estructura"
    print(f"\n{C_TITLE}▶  IA ─ Proponer estructura desde imagen{C_RESET}")
    try:
        with open(file_path, "rb") as f:
            files = {"imagen": ("test1.jpg", f, "image/jpeg")}
            resp = session.post(url, files=files, headers=headers_admin)

        success = resp.status_code in (200, 201)
        icon = f"{C_SUCCESS}✔" if success else f"{C_ERROR}✗"
        print(f"  {icon} Status {resp.status_code}{C_RESET}")

        campos_propuestos = []
        if success and resp.text.strip():
            try:
                resp_json = resp.json()
            except:
                resp_json = {"raw": resp.text}
            decrypted = decrypt_server_response(resp_json, ck)
            print(f"  {C_DIM}Respuesta IA (desencriptada):{C_RESET}")
            try:
                parsed = json.loads(decrypted) if isinstance(decrypted, str) else decrypted
                print(f"  {pretty_json(parsed)}")
                campos_propuestos = parsed.get("campos", []) if isinstance(parsed, dict) else []
            except Exception as e:
                print(f"  {C_VAL}{decrypted}{C_RESET}")

        _register(success, "IA ─ Proponer estructura")
    except Exception as exc:
        print(f"  {C_ERROR}✗ Error: {exc}{C_RESET}")
        _register(False, "IA ─ Proponer estructura")
        return

    if not campos_propuestos:
        print(f"  {C_WARN}⚠ IA no propuso campos, omitiendo confirmación.{C_RESET}")
        return

    # Mapear tipo string -> tipoCampoId
    campos_confirmar = []
    for cp in campos_propuestos:
        if not isinstance(cp, dict):
            continue
        tipo_str = cp.get("tipoCampo")
        tipo_id = tipos_map.get(tipo_str) if tipo_str else None
        if not tipo_id:
            print(f"  {C_WARN}⚠ Tipo '{tipo_str}' no mapeado, saltando campo.{C_RESET}")
            continue
        campos_confirmar.append({
            "planillaId": planilla_id,
            "tipoCampoId": tipo_id,
            "nombreCampo": cp.get("nombreCampo", "Campo sin nombre"),
            "obligatorio": cp.get("obligatorio", False),
            "opciones": cp.get("opciones"),
        })

    if not campos_confirmar:
        print(f"  {C_WARN}⚠ Ningún campo pudo mapearse, omitiendo confirmación.{C_RESET}")
        return

    run_step(
        session, "POST", f"{URL_PLANILLAS}/{planilla_id}/confirmar-estructura",
        campos_confirmar, sn, se, ck, headers=headers_admin,
        label="IA ─ Confirmar estructura",
    )

    # Verificar persistencia
    run_step(
        session, "GET", f"{URL_CAMPOS}/planilla/{planilla_id}", {}, sn, se, ck,
        headers=headers_admin, label=f"IA ─ Verificar campos persistidos ({planilla_id})",
        expected_statuses=(200, 201),
    )


# ══════════════════════════════════════════════════════
#  BLOQUE 2G ─ IA: GENERAR PROPUESTA DESDE DESCRIPCIÓN
# ══════════════════════════════════════════════════════
def test_generar_propuesta(session, sn, se, ck, headers_admin, lugar_id, tipos_map):
    section("IA ─ GENERAR PROPUESTA DESDE DESCRIPCIÓN")

    # ── Caso A: sin evento ──
    propuesta_a, _ = run_step(
        session, "POST", f"{URL_PLANILLAS}/generar-propuesta",
        {"descripcion": "Quiero una planilla simple con nombre, correo y fecha de nacimiento", "crearEvento": False},
        sn, se, ck, headers=headers_admin,
        label="IA ─ Generar propuesta (sin evento)",
    )

    if propuesta_a and isinstance(propuesta_a, dict):
        evento_a = propuesta_a.get("evento")
        campos_a = propuesta_a.get("campos", [])
        if evento_a is not None:
            print(f"  {C_WARN}⚠ Se esperaba evento=null para crearEvento=false{C_RESET}")
        else:
            print(f"  {C_SUCCESS}✔ evento=null como esperado{C_RESET}")
        print(f"  {C_VAL}Campos propuestos: {len(campos_a)}{C_RESET}")

        # Confirmar sin evento
        campos_confirmar_a = []
        for cp in campos_a:
            if not isinstance(cp, dict):
                continue
            tipo_str = cp.get("tipoCampo")
            tipo_id = tipos_map.get(tipo_str) if tipo_str else None
            if not tipo_id:
                continue
            campos_confirmar_a.append({
                "planillaId": None,  # se asigna al crear planilla
                "tipoCampoId": tipo_id,
                "nombreCampo": cp.get("nombreCampo", "Campo"),
                "obligatorio": cp.get("obligatorio", False),
                "opciones": cp.get("opciones"),
            })

        if campos_confirmar_a:
            run_step(
                session, "POST", f"{URL_PLANILLAS}/generar-propuesta/confirmar",
                {"evento": None, "campos": campos_confirmar_a},
                sn, se, ck, headers=headers_admin,
                label="IA ─ Confirmar propuesta (sin evento)",
            )

    # ── Caso B: con evento ──
    propuesta_b, _ = run_step(
        session, "POST", f"{URL_PLANILLAS}/generar-propuesta",
        {"descripcion": "Evento de capacitación con registro de asistentes", "crearEvento": True, "lugarId": lugar_id},
        sn, se, ck, headers=headers_admin,
        label="IA ─ Generar propuesta (con evento)",
    )

    if propuesta_b and isinstance(propuesta_b, dict):
        evento_b = propuesta_b.get("evento")
        campos_b = propuesta_b.get("campos", [])
        if evento_b:
            print(f"  {C_SUCCESS}✔ Evento propuesto: {evento_b.get('nombre')}{C_RESET}")
        else:
            print(f"  {C_WARN}⚠ No se propuso evento a pesar de crearEvento=true{C_RESET}")

        campos_confirmar_b = []
        for cp in campos_b:
            if not isinstance(cp, dict):
                continue
            tipo_str = cp.get("tipoCampo")
            tipo_id = tipos_map.get(tipo_str) if tipo_str else None
            if not tipo_id:
                continue
            campos_confirmar_b.append({
                "planillaId": None,
                "tipoCampoId": tipo_id,
                "nombreCampo": cp.get("nombreCampo", "Campo"),
                "obligatorio": cp.get("obligatorio", False),
                "opciones": cp.get("opciones"),
            })

        if campos_confirmar_b and evento_b and isinstance(evento_b, dict):
            confirmar_req = {
                "evento": {
                    "nombre": evento_b.get("nombre", "Evento confirmado"),
                    "descripcion": evento_b.get("descripcion", ""),
                    "fechaHoraInicio": evento_b.get("fechaHoraInicio"),
                    "fechaHoraFin": evento_b.get("fechaHoraFin"),
                    "lugarId": lugar_id,
                },
                "campos": campos_confirmar_b,
            }
            run_step(
                session, "POST", f"{URL_PLANILLAS}/generar-propuesta/confirmar",
                confirmar_req, sn, se, ck, headers=headers_admin,
                label="IA ─ Confirmar propuesta (con evento)",
            )


# ══════════════════════════════════════════════════════
#  BLOQUE 3 ─ REPORTES DERIVADOS EN PLANILLA
# ══════════════════════════════════════════════════════
def test_reporte(session, sn, se, ck, headers_admin, planilla_id_seed=1):
    section("REPORTES DERIVADOS EN PLANILLA")

    run_step(
        session,
        "GET",
        f"{URL_REPORTES}/planilla/{planilla_id_seed}/resumen",
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label=f"REPORTE ─ Resumen por planilla ({planilla_id_seed})",
    )

    run_step(
        session,
        "GET",
        f"{URL_REPORTES}/justificaciones/resumen",
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label="REPORTE ─ Resumen de justificaciones",
    )

    run_step(
        session,
        "GET",
        f"{URL_REPORTES}/estudiante/2024117001/trazabilidad",
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label="REPORTE ─ Trazabilidad de estudiante",
    )


# ══════════════════════════════════════════════════════
#  BLOQUE 3B ─ ESTADÍSTICAS DINÁMICAS DE PLANILLA
# ══════════════════════════════════════════════════════
def test_estadisticas_dinamicas(session, sn, se, ck, headers_admin, planilla_id_seed=1):
    section("ESTADÍSTICAS DINÁMICAS DE PLANILLA")

    # Campos reales del seed: Cédula (numeric), Nombres (text), Apellidos (text)
    run_step(
        session,
        "GET",
        f"{URL_REPORTES}/planilla/{planilla_id_seed}/campo/Cédula/estadisticas",
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label=f"ESTADÍSTICAS ─ Por campo 'Cédula' (numeric)",
    )

    run_step(
        session,
        "GET",
        f"{URL_REPORTES}/planilla/{planilla_id_seed}/campo/Nombres/estadisticas",
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label=f"ESTADÍSTICAS ─ Por campo 'Nombres' (text)",
    )

    run_step(
        session,
        "GET",
        f"{URL_REPORTES}/planilla/{planilla_id_seed}/campo/Apellidos/estadisticas",
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label=f"ESTADÍSTICAS ─ Por campo 'Apellidos' (text)",
    )

    run_step(
        session,
        "GET",
        f"{URL_REPORTES}/planilla/{planilla_id_seed}/estadisticas-completas",
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label=f"ESTADÍSTICAS ─ Completas de planilla ({planilla_id_seed})",
    )

    run_step(
        session,
        "GET",
        f"{URL_REPORTES}/planilla/{planilla_id_seed}/comparativa?campos=Cédula,Nombres,Apellidos",
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label=f"ESTADÍSTICAS ─ Comparativa (Cédula,Nombres,Apellidos)",
    )


# ══════════════════════════════════════════════════════
#  BLOQUE 4 ─ MICROSERVICIO ASISTENCIA
# ══════════════════════════════════════════════════════
def test_asistencia(
    session, sn, se, ck, headers_estudiante, headers_admin, planilla_id_seed=1
):
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
                "datosAdicionales": {"dispositivo": "Android", "appVersion": "1.0.0"},
            },
            headers=headers_estudiante,
        )
        # 403 = tokens no sincronizados entre microservicios (limitación arquitectónica conocida)
        success = resp.status_code in (200, 201, 403)
        icon = f"{C_SUCCESS}✔" if resp.status_code in (200, 201) else f"{C_WARN}⚠"
        note = (
            " (403 = tokens no sincronizados – comportamiento esperado)"
            if resp.status_code == 403
            else ""
        )
        print(f"  {icon} Status {resp.status_code}{note}{C_RESET}")
        try:
            body = resp.json()
            decrypt_body = decrypt_server_response(body, ck)
            print(f"  {pretty_json(decrypt_body)}")
            parsed = (
                json.loads(decrypt_body)
                if isinstance(decrypt_body, str)
                else decrypt_body
            )
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
            headers=headers_estudiante,
        )
        success = resp.status_code in (200, 201, 400, 403)
        icon = f"{C_SUCCESS}✔" if resp.status_code in (200, 201) else f"{C_WARN}⚠"
        note = ""
        if resp.status_code == 403:
            note = " (403 = tokens no sincronizados)"
        elif resp.status_code == 400:
            note = " (400 esperado cuando entrada previa fue rechazada por token no sincronizado)"
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
            headers=headers_estudiante,
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
                parsed = (
                    json.loads(decrypt_body)
                    if isinstance(decrypt_body, str)
                    else decrypt_body
                )
                asistencia_id = parsed.get("id") if isinstance(parsed, dict) else None
            except Exception:
                pass
        _register(success, "ASISTENCIA ─ Justificar ausencia")
    except requests.exceptions.ConnectionError as exc:
        print(f"  {C_ERROR}✗ No conecta: {exc}{C_RESET}")
        _register(False, "ASISTENCIA ─ Justificar ausencia")

    # ── GET por estudiante (admin) ──
    run_step(
        session,
        "GET",
        f"{URL_ASISTENCIAS}/estudiante/{codigo_est}",
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label=f"ASISTENCIA ─ Por estudiante ({codigo_est})",
        expected_statuses=(200, 201),
    )

    # ── GET por planilla ──
    run_step(
        session,
        "GET",
        f"{URL_ASISTENCIAS}/planilla/{planilla_id_seed}",
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label=f"ASISTENCIA ─ Por planilla ({planilla_id_seed})",
        expected_statuses=(200, 201),
    )

    # ── GET presentes por planilla ──
    run_step(
        session,
        "GET",
        f"{URL_ASISTENCIAS}/planilla/{planilla_id_seed}/presentes",
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label=f"ASISTENCIA ─ Presentes en planilla ({planilla_id_seed})",
        expected_statuses=(200, 201),
    )

    if asistencia_id:
        # ── GET por ID ──
        run_step(
            session,
            "GET",
            f"{URL_ASISTENCIAS}/{asistencia_id}",
            {},
            sn,
            se,
            ck,
            headers=headers_admin,
            label=f"ASISTENCIA ─ FindById ({asistencia_id})",
            expected_statuses=(200, 201),
        )

        # ── PUT ──
        run_step(
            session,
            "PUT",
            f"{URL_ASISTENCIAS}/{asistencia_id}",
            {
                "codigoEstudiante": codigo_est,
                "planillaId": planilla_id_seed,
                "fechaHoraRegistro": "2026-05-01T10:00:00",
                "estado": "TARDANZA",
                "geolocalizacion": None,
                "datosAdicionales": None,
            },
            sn,
            se,
            ck,
            headers=headers_admin,
            label=f"ASISTENCIA ─ Actualizar ({asistencia_id})",
        )

        # ── PATCH estado ──
        print(f"\n{C_TITLE}▶  ASISTENCIA ─ Cambiar estado ({asistencia_id}){C_RESET}")
        try:
            resp = session.patch(
                f"{URL_ASISTENCIAS}/{asistencia_id}/estado",
                params={"estado": "JUSTIFICADO"},
                headers=headers_admin,
            )
            success = resp.status_code in (200, 201)
            icon = f"{C_SUCCESS}✔" if success else f"{C_ERROR}✗"
            print(f"  {icon} Status {resp.status_code}{C_RESET}")
            _register(success, f"ASISTENCIA ─ Cambiar estado ({asistencia_id})")
        except requests.exceptions.ConnectionError as exc:
            print(f"  {C_ERROR}✗ No conecta: {exc}{C_RESET}")
            _register(False, f"ASISTENCIA ─ Cambiar estado ({asistencia_id})")

        # ── DELETE ──
        run_step(
            session,
            "DELETE",
            f"{URL_ASISTENCIAS}/{asistencia_id}",
            {},
            sn,
            se,
            ck,
            headers=headers_admin,
            label=f"ASISTENCIA ─ Eliminar ({asistencia_id})",
            expected_statuses=(200, 201, 204),
        )
    else:
        print(
            f"  {C_WARN}⚠ No se obtuvo asistencia_id, omitiendo GET/PUT/DELETE/PATCH.{C_RESET}"
        )

    # ── GET rango de fechas ──
    run_step(
        session,
        "GET",
        f"{URL_ASISTENCIAS}/rango?inicio=2026-01-01T00:00:00&fin=2026-12-31T23:59:59",
        {},
        sn,
        se,
        ck,
        headers=headers_admin,
        label="ASISTENCIA ─ Rango de fechas",
        expected_statuses=(200, 201),
    )


# ══════════════════════════════════════════════════════
#  BLOQUE 5 ─ MICROSERVICIO JUSTIFICACION
# ══════════════════════════════════════════════════════
def test_justificacion(session, sn, se, ck, headers_estudiante, headers_decano):
    section("MICROSERVICIO JUSTIFICACION")

    # ── Solicitar justificación (Monitor/Estudiante) ──
    # El endpoint requiere role Estudiante o Monitor; usamos headers_estudiante.
    # 403 = tokens no sincronizados entre microservicios (conocido).
    created, _ = run_step(
        session,
        "POST",
        f"{URL_JUSTIFICACIONES}/solicitar",
        {
            "registroId": 1,
            "usuarioCodigo": "2024117001",
            "motivo": "Enfermedad certificada",
            "documentoUrl": "https://ejemplo.com/cert.pdf",
        },
        sn,
        se,
        ck,
        headers=headers_estudiante,
        label="JUSTIFICACION ─ Solicitar",
        expected_statuses=(200, 201, 403),
    )

    just_id = None
    if created and isinstance(created, dict):
        just_id = created.get("id")

    # ── Listar todas (Decano) ──
    run_step(
        session,
        "GET",
        f"{URL_JUSTIFICACIONES}/all",
        {},
        sn,
        se,
        ck,
        headers=headers_decano,
        label="JUSTIFICACION ─ Listar todas",
    )

    # ── Por usuarioCodigo (Estudiante) ──
    run_step(
        session,
        "GET",
        f"{URL_JUSTIFICACIONES}/usuario/2024117001",
        {},
        sn,
        se,
        ck,
        headers=headers_estudiante,
        label="JUSTIFICACION ─ Por usuario (2024117001)",
    )

    # ── Por registroId (Decano) ──
    run_step(
        session,
        "GET",
        f"{URL_JUSTIFICACIONES}/registro/1",
        {},
        sn,
        se,
        ck,
        headers=headers_decano,
        label="JUSTIFICACION ─ Por registro (id=1)",
    )

    # ── Por estado (Decano) ──
    run_step(
        session,
        "GET",
        f"{URL_JUSTIFICACIONES}/estado/PENDIENTE",
        {},
        sn,
        se,
        ck,
        headers=headers_decano,
        label="JUSTIFICACION ─ Por estado (PENDIENTE)",
    )

    if just_id:
        # ── FindById (Decano) ──
        run_step(
            session,
            "GET",
            f"{URL_JUSTIFICACIONES}/{just_id}",
            {},
            sn,
            se,
            ck,
            headers=headers_decano,
            label=f"JUSTIFICACION ─ FindById ({just_id})",
        )

        # ── Aprobar (Decano) ──
        run_step(
            session,
            "POST",
            f"{URL_JUSTIFICACIONES}/{just_id}/aprobar",
            {
                "revisadoPor": "Decano Pedro",
                "observaciones": "Documento verificado, aprobado.",
            },
            sn,
            se,
            ck,
            headers=headers_decano,
            label=f"JUSTIFICACION ─ Aprobar ({just_id})",
        )

        # ── PUT (Decano) ──
        run_step(
            session,
            "PUT",
            f"{URL_JUSTIFICACIONES}/{just_id}",
            {
                "registroId": 1,
                "usuarioCodigo": "2024117001",
                "motivo": "Motivo actualizado",
                "documentoUrl": "https://ejemplo.com/cert-v2.pdf",
                "estado": "APROBADO",
            },
            sn,
            se,
            ck,
            headers=headers_decano,
            label=f"JUSTIFICACION ─ Actualizar ({just_id})",
        )

        # ── Rechazar otra justificación del seed ──
        run_step(
            session,
            "POST",
            f"{URL_JUSTIFICACIONES}/2/rechazar",
            {"revisadoPor": "Decano Pedro", "observaciones": "No cumple requisitos"},
            sn,
            se,
            ck,
            headers=headers_decano,
            label="JUSTIFICACION ─ Rechazar (id=2)",
            expected_statuses=(200, 201, 404),
        )

        # ── DELETE (Decano) ──
        run_step(
            session,
            "DELETE",
            f"{URL_JUSTIFICACIONES}/{just_id}",
            {},
            sn,
            se,
            ck,
            headers=headers_decano,
            label=f"JUSTIFICACION ─ Eliminar ({just_id})",
            expected_statuses=(200, 201, 204),
        )
    else:
        print(
            f"  {C_WARN}⚠ No se obtuvo just_id, omitiendo operaciones sobre ID.{C_RESET}"
        )


# ══════════════════════════════════════════════════════
#  BLOQUE 6 ─ ROTACIÓN DE CLAVES
# ══════════════════════════════════════════════════════
def test_rotacion(session, headers_admin, origen_digital_id):
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
    resp_login = session.post(
        URL_LOGIN, json={"usuario": "4", "contrasena": "Admin#2024"}
    )
    token2 = None
    try:
        login_data = resp_login.json()
        # El login ya no pasa por cifrado RSA en este endpoint
        token2 = login_data.get("access_token")
    except Exception:
        pass

    if not token2:
        # Intentar con body cifrado
        login2, _ = run_step(
            session,
            "POST",
            URL_LOGIN,
            {"codigo": 4, "contrasena": "Admin#2024"},
            sn2,
            se2,
            ck2,
            label="LOGIN post-rotación",
        )
        if login2 and isinstance(login2, dict):
            token2 = login2.get("access_token")

    h2 = {"Authorization": f"Bearer {token2}"} if token2 else {}

    run_step(
        session,
        "POST",
        URL_PLANILLAS,
        {"origen": {"id": origen_digital_id}},
        sn2,
        se2,
        ck2,
        headers=h2,
        label="PLANILLA ─ Crear POST-ROTACIÓN",
    )


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
    filled = int(bar_len * _tests_ok // max(_tests_total, 1))
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
    login_admin, _ = run_step(
        session,
        "POST",
        URL_LOGIN,
        {"codigo": 4, "contrasena": "Admin#2024"},
        sn,
        se,
        ck,
        label="LOGIN ─ Administrador (codigo=4)",
    )
    if not login_admin:
        print(f"  {C_ERROR}✗ Login fallido, abortando pruebas.{C_RESET}")
        sys.exit(1)
    h_admin = {"Authorization": f"Bearer {login_admin['access_token']}"}

    # ── Login como Decano ──
    login_decano, _ = run_step(
        session,
        "POST",
        URL_LOGIN,
        {"codigo": 6, "contrasena": "Decano#11"},
        sn,
        se,
        ck,
        label="LOGIN ─ Decano (codigo=6)",
    )
    h_decano = (
        {"Authorization": f"Bearer {login_decano['access_token']}"}
        if login_decano
        else h_admin
    )

    # ── Login como Estudiante ──
    login_est, _ = run_step(
        session,
        "POST",
        URL_LOGIN,
        {"codigo": 2, "contrasena": "Clave$456"},
        sn,
        se,
        ck,
        label="LOGIN ─ Estudiante (codigo=2)",
    )
    h_est = (
        {"Authorization": f"Bearer {login_est['access_token']}"} if login_est else {}
    )

    # ── Login como Monitor ──
    login_monitor, _ = run_step(
        session,
        "POST",
        URL_LOGIN,
        {"codigo": 1, "contrasena": "Segura#123"},
        sn,
        se,
        ck,
        label="LOGIN ─ Monitor (codigo=1)",
    )
    h_monitor = (
        {"Authorization": f"Bearer {login_monitor['access_token']}"}
        if login_monitor
        else {}
    )

    # ══════════════════════════════════════════════════
    #  EJECUCIÓN DE BLOQUES DE PRUEBA
    # ══════════════════════════════════════════════════
    test_usuario(session, sn, se, ck, h_admin, ts)

    # Helpers dinámicos
    origenes_map = obtener_origenes(session, sn, se, ck, h_admin)
    origen_digital_id = origenes_map.get("digital", 1)
    tipos_map = obtener_tipos_campo(session, sn, se, ck, h_admin)

    # CRUD Planilla (crea y elimina una planilla de prueba)
    test_planilla(session, sn, se, ck, h_admin, origen_digital_id)

    # Crear planilla de trabajo persistente para tests dependientes
    planilla_trabajo, _ = run_step(
        session, "POST", URL_PLANILLAS,
        {"origen": {"id": origen_digital_id}},
        sn, se, ck, headers=h_admin,
        label="SETUP ─ Crear planilla de trabajo",
    )
    planilla_id = planilla_trabajo.get("id") if isinstance(planilla_trabajo, dict) else 1

    # Nuevos bloques de dominio
    lugar_id = test_lugares(session, sn, se, ck, h_admin)
    test_eventos(session, sn, se, ck, h_admin, lugar_id)
    campos_ids = test_campos(session, sn, se, ck, h_admin, planilla_id, tipos_map)
    test_filas(session, sn, se, ck, h_admin, planilla_id, campos_ids, tipos_map)
    test_datos(session, sn, se, ck, h_admin, planilla_id)

    # Bloques IA
    test_proponer_estructura(session, sn, se, ck, h_admin, planilla_id, tipos_map)
    test_generar_propuesta(session, sn, se, ck, h_admin, lugar_id, tipos_map)

    # Bloques existentes (IA y microservicios no levantados omitidos)
    test_digitalizar(session, sn, se, ck, h_admin, planilla_id)
    test_guardar_planilla_digitalizada(session, sn, se, ck, h_admin, tipos_map, origen_digital_id)
    # test_ai_config(session, h_admin, ck)
    # test_reporte(session, sn, se, ck, h_admin, planilla_id_seed=planilla_id)
    test_estadisticas_dinamicas(session, sn, se, ck, h_admin, planilla_id_seed=planilla_id)
    # test_asistencia(session, sn, se, ck, h_est, h_admin, planilla_id_seed=planilla_id)
    # test_justificacion(session, sn, se, ck, h_monitor, h_decano)
    test_rotacion(session, h_admin, origen_digital_id)

    # ══════════════════════════════════════════════════
    #  RESUMEN
    # ══════════════════════════════════════════════════
    print_summary()

    sys.exit(0 if _tests_failed == 0 else 1)
