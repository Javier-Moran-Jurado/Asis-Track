import requests
import json
import base64
from Crypto.Util.number import getPrime, inverse
import sys
import time
import re

# Colores (ANSI RGB)
C_TITLE = "\033[38;2;0;140;255m"
C_KEY = "\033[38;2;0;179;107m"
C_VAL = "\033[38;2;255;171;92m"
C_RESET = "\033[0m"

# URLs
URL_SEGURIDAD = "http://localhost:8091/api/v1/security/keys/public"
URL_ROTATE = "http://localhost:8091/api/v1/security/keys/rotate"
URL_SESSION_KEY = "http://localhost:8080/api/v1/auth/session-key"
URL_LOGIN = "http://localhost:8080/api/v1/auth/login"
URL_USUARIOS = "http://localhost:8080/api/v1/usuario-service/usuarios"

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
        text_bytes = text.encode('utf-8')
        chunks = []
        for i in range(0, len(text_bytes), chunk_size):
            chunk = text_bytes[i:i+chunk_size]
            m = int.from_bytes(chunk, byteorder='big', signed=False)
            c = pow(m, e, n)
            chunks.append(str(c))
        return ",".join(chunks)

    @staticmethod
    def decrypt(cipher_text_decimal, n, d):
        if not cipher_text_decimal: return ""
        parts = cipher_text_decimal.split(",")
        decrypted_chunks = []
        for part in parts:
            try:
                c = int(part)
                m = pow(c, d, n)
                byte_length = (m.bit_length() + 7) // 8
                if byte_length == 0: byte_length = 1
                decrypted_chunk = m.to_bytes(byte_length, byteorder='big', signed=False).decode('utf-8')
                decrypted_chunks.append(decrypted_chunk)
            except: decrypted_chunks.append("[Err]")
        return "".join(decrypted_chunks)

def color_json(json_str):
    json_str = re.sub(r'(".*?")\s*:', f'{C_KEY}\\1{C_RESET}:', json_str)
    json_str = re.sub(r':\s*(".*?")', f': {C_VAL}\\1{C_RESET}', json_str)
    json_str = re.sub(r':\s*([0-9\.]+|true|false|null)(?=[,\s\}]|$)', f': {C_VAL}\\1{C_RESET}', json_str)
    return json_str

def pretty_json(data):
    if isinstance(data, str):
        try: data = json.loads(data)
        except: pass
    return color_json(json.dumps(data, indent=2, ensure_ascii=False))

def decrypt_server_response(resp_json, client_key):
    if isinstance(resp_json, dict) and "encryptedData" in resp_json:
        try:
            b64_data = resp_json["encryptedData"]
            decimal_cipher = base64.b64decode(b64_data).decode('utf-8')
            return CustomRSA.decrypt(decimal_cipher, client_key['n'], client_key['d'])
        except: return str(resp_json)
    return json.dumps(resp_json)

def run_step(session, method, url, body_dict, server_n, server_e, client_key, headers=None, label="STEP"):
    print(f"\n{C_TITLE}--- {label} ---{C_RESET}")
    plain_json = json.dumps(body_dict)
    encrypted_body = CustomRSA.encrypt(plain_json, server_n, server_e)
    
    mapping = {"POST": session.post, "PUT": session.put, "DELETE": session.delete, "GET": session.get}
    func = mapping.get(method)
    
    if method in ["POST", "PUT", "DELETE"]:
        resp = func(url, json={"encryptedData": encrypted_body}, headers=headers)
    else:
        resp = func(url, headers=headers)

    resp_json = resp.json() if resp.text else {}
    decrypted = decrypt_server_response(resp_json, client_key)
    
    if resp.status_code in [200, 201]:
        print(f"[+] Éxito (Status {resp.status_code})")
        print(f"[*] Respuesta Desencriptada:\n{pretty_json(decrypted)}")
        try: return json.loads(decrypted)
        except: return decrypted
    else:
        print(f"[!] Error {resp.status_code}: {decrypted}")
        return None

def start_session(session):
    resp = requests.get(URL_SEGURIDAD)
    server_key = resp.json()
    sn, se = int(server_key['publicN']), int(server_key['publicE'])
    ck = CustomRSA.generate_key_pair()
    reg_payload = json.dumps({"n": str(ck['n']), "e": str(ck['e'])})
    enc_reg = CustomRSA.encrypt(reg_payload, sn, se)
    session.post(URL_SESSION_KEY, json={"encryptedPayload": enc_reg})
    return sn, se, ck, server_key['id']

if __name__ == "__main__":
    session = requests.Session()
    ts = int(time.time()) % 10000
    
    print(f"{C_TITLE}=== TURNO 1: OPERACIONES ==={C_RESET}")
    sn1, se1, ck1, sid1 = start_session(session)
    print(f"Sesión con Servidor ID={sid1}")

    login1 = run_step(session, "POST", URL_LOGIN, {"codigo": 4, "contrasena": "Admin#2024"}, sn1, se1, ck1, label="LOGIN")
    if not login1: sys.exit(1)
    h1 = {"Authorization": f"Bearer {login1['access_token']}"}

    # CREATE unique
    run_step(session, "POST", URL_USUARIOS, {
        "codigo": 7000 + ts, "nombreCompleto": f"User T1-{ts}", "correo": f"t1-{ts}@test.com",
        "contrasena": "PassWd#1", "cedula": ts, "telefono": ts, "rol": "Monitor"
    }, sn1, se1, ck1, headers=h1, label=f"CREATE ({7000+ts})")

    # UPDATE 1
    run_step(session, "PUT", URL_USUARIOS, {
        "codigo": 1, "nombreCompleto": f"Juan Editado {ts}", "correo": "juan.perez@uceva.edu.co",
        "contrasena": "Segura#123", "cedula": 100, "telefono": 100, "rol": "Monitor"
    }, sn1, se1, ck1, headers=h1, label="UPDATE (1)")

    # DELETE 3
    run_step(session, "DELETE", URL_USUARIOS, {"codigo": 7}, sn1, se1, ck1, headers=h1, label="DELETE (3)")

    print(f"\n{C_TITLE}=== ROTANDO CLAVES ==={C_RESET}")
    requests.post(URL_ROTATE, headers=h1)
    
    print(f"\n{C_TITLE}=== TURNO 2: TRAS ROTACIÓN ==={C_RESET}")
    # Nota: Sin flush_redis, usuarioservice todavía tiene la llave ID anterior.
    # El paso start_session obtendrá la NUEVA llave del servidor de seguridad,
    # pero al enviarla a usuarioservice/session-key, este intentará desencriptar con la llave VIEJA.
    sn2, se2, ck2, sid2 = start_session(session)
    print(f"Sesión con Servidor ID={sid2}")

    # Este paso probablemente fallará due to cache
    run_step(session, "POST", URL_USUARIOS, {
        "codigo": 8000 + ts, "nombreCompleto": f"User T2-{ts}", "correo": f"t2-{ts}@test.com",
        "contrasena": "PassWd#2", "cedula": ts+1, "telefono": ts+1, "rol": "Estudiante"
    }, sn2, se2, ck2, headers=h1, label=f"CREATE TRAS ROTACIÓN ({8000+ts})")

    run_step(session, "GET", URL_USUARIOS, {}, sn2, se2, ck2, headers=h1, label="LISTAR FINAL")
