#!/usr/bin/env python3
import os
import sys
import json
import time
import requests
import base64
import hmac
import hashlib

# ─── Colores ANSI ───────────────────────────────────────────────────────────
RESET, BOLD, DIM = "\033[0m", "\033[1m", "\033[2m"
WHITE, YELLOW, GREEN, RED, CYAN, MAGENTA, BLUE = "\033[97m", "\033[93m", "\033[92m", "\033[91m", "\033[96m", "\033[95m", "\033[94m"

# ─── Configuración ──────────────────────────────────────────────────────────
BASE_URL   = os.environ.get("PLANILLA_URL", "http://localhost:8084")
ENDPOINT   = f"{BASE_URL}/api/v1/planilla-service/planillas/digitalizar"
IMAGES_DIR = os.path.join(os.path.dirname(__file__), "testImages")
SECRET_KEY = "1ba088eedd1f27c54639e8e2d3a02cc950cfb0f31d3292fa60010014352b9ff9"

def base64url_encode(data):
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('utf-8')

def generate_token_manual():
    # Header
    header = {"alg": "HS256", "typ": "JWT"}
    header_enc = base64url_encode(json.dumps(header).encode())
    
    # Payload ajustado según JwtService.java del microservicio Planilla
    now = int(time.time())
    payload = {
        "jti": "4",
        "sub": "correo4",
        "iat": now,
        "exp": now + 3600,
        "rol": "Administrador",
        "nombre_completo": "Nombre4"
    }
    payload_enc = base64url_encode(json.dumps(payload).encode())
    
    # Signature (Decoders.BASE64.decode(secretKey))
    try:
        # El microservicio usa io.jsonwebtoken.io.Decoders.BASE64.decode(secretKey)
        # Esto espera un string base64 estándar y lo convierte a bytes.
        key_bytes = base64.b64decode(SECRET_KEY)
    except Exception as e:
        print(f"Error decodificando clave base64: {e}. Usando clave raw.")
        key_bytes = SECRET_KEY.encode()
        
    signing_input = f"{header_enc}.{payload_enc}".encode()
    signature = hmac.new(key_bytes, signing_input, hashlib.sha256).digest()
    sig_enc = base64url_encode(signature)
    
    return f"{header_enc}.{payload_enc}.{sig_enc}"

def print_json(data):
    try:
        parsed = json.loads(data) if isinstance(data, str) else data
        print(f"{BLUE}{json.dumps(parsed, indent=4, ensure_ascii=False)}{RESET}")
    except:
        print(f"{WHITE}{data}{RESET}")

def main():
    print(f"\n{BOLD}{CYAN}🤖 PRUEBA ENDPOINT IA — INTENTO 4 (BASE64 DECODE KEY){RESET}")
    token = generate_token_manual()
    print(f"  {MAGENTA}Token generado con decodificación de clave.{RESET}\n")

    if not os.path.isdir(IMAGES_DIR):
        print(f"{RED}Error: Directorio {IMAGES_DIR} no encontrado.{RESET}")
        return

    images = sorted([os.path.join(IMAGES_DIR, f) for f in os.listdir(IMAGES_DIR) if f.lower().endswith((".jpg", ".jpeg", ".png"))])
    
    for i, img_path in enumerate(images, 1):
        filename = os.path.basename(img_path)
        print(f"{BOLD}{BLUE}[{i}/{len(images)}] Enviando: {filename}{RESET}")
        try:
            with open(img_path, "rb") as f:
                response = requests.post(
                    ENDPOINT, 
                    headers={"Authorization": f"Bearer {token}"}, 
                    files={"file": (filename, f, "image/jpeg")},
                    timeout=300
                )
            color = GREEN if response.status_code == 200 else RED
            print(f"  {BOLD}Status: {color}{response.status_code}{RESET}")
            print_json(response.text)
        except Exception as e:
            print(f"  {RED}Error: {e}{RESET}")
        print("-" * 60)

if __name__ == "__main__":
    main()
