import requests
import json

BASE_URL = "http://localhost:8080"

def test_oauth2_google():
    url = f"{BASE_URL}/api/v1/auth/oauth2/google"
    headers = {"Content-Type": "application/json"}

    print("=" * 60)
    print("PRUEBAS DEL ENDPOINT /api/v1/auth/oauth2/google")
    print("=" * 60)

    # --- Prueba 1: Token vacio ---
    print("\n[Prueba 1] Token vacio")
    payload = {"idToken": ""}
    try:
        r = requests.post(url, headers=headers, json=payload, timeout=10)
        print(f"  Status: {r.status_code}")
        print(f"  Respuesta: {r.text}")
    except Exception as e:
        print(f"  ERROR: {e}")

    # --- Prueba 2: Token invalido (firma falsa) ---
    print("\n[Prueba 2] Token invalido (firma falsa)")
    fake_token = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImZha2UiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiIxMjM0NTY3ODktYWJjLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwiYXVkIjoiMTIzNDU2Nzg5LWFiYy5hcHBzLmdvb2dsZXVzZXJjb250ZW50LmNvbSIsInN1YiI6IjEyMzQ1Njc4OTAiLCJlbWFpbCI6InRlc3RAdWNldmEuZWR1LmNvIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsIm5hbWUiOiJUZXN0IFVzZXIiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tLyIsImdpdmVuX25hbWUiOiJUZXN0IiwiZmFtaWx5X25hbWUiOiJVc2VyIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjE3MDAwMDM2MDB9.invalid_signature"
    payload = {"idToken": fake_token}
    try:
        r = requests.post(url, headers=headers, json=payload, timeout=10)
        print(f"  Status: {r.status_code}")
        print(f"  Respuesta: {r.text}")
    except Exception as e:
        print(f"  ERROR: {e}")

    # --- Prueba 3: Token valido estructuralmente pero dominio no institucional ---
    print("\n[Prueba 3] Dominio no institucional (@gmail.com)")
    print("  NOTA: Necesitas un idToken REAL de Google para esta prueba.")
    print("  Instrucciones:")
    print("  1. Ve a https://developers.google.com/oauthplayground")
    print("  2. Selecciona scope 'openid email profile'")
    print("  3. Autoriza con una cuenta @gmail.com")
    print("  4. Intercambia el authorization code por tokens")
    print("  5. Copia el id_token y pegalo aqui en la variable REAL_ID_TOKEN")
    REAL_ID_TOKEN = "<PEGA_AQUI_EL_ID_TOKEN_REAL>"
    if REAL_ID_TOKEN != "<PEGA_AQUI_EL_ID_TOKEN_REAL>":
        payload = {"idToken": REAL_ID_TOKEN}
        try:
            r = requests.post(url, headers=headers, json=payload, timeout=10)
            print(f"  Status: {r.status_code}")
            print(f"  Respuesta: {r.text}")
        except Exception as e:
            print(f"  ERROR: {e}")
    else:
        print("  [SALTADO] No se proporciono un idToken real.")

    print("\n" + "=" * 60)
    print("FIN DE PRUEBAS")
    print("=" * 60)


def test_login_manual():
    url = f"{BASE_URL}/api/v1/auth/login"
    headers = {"Content-Type": "application/json"}

    print("\n" + "=" * 60)
    print("PRUEBA DEL LOGIN MANUAL (sin cambios)")
    print("=" * 60)
    print("  Este endpoint deberia seguir funcionando igual que antes.")
    print("  Usa Postman o curl para probar con un usuario real de la BD.")
    print(f"  POST {url}")
    print('  Body: {"codigo": 1234567890, "contrasena": "tu_contrasena"}')


if __name__ == "__main__":
    print("Script de prueba para OAuth2 Google - Asis-Track")
    print("Asegurate de que el backend este corriendo en http://localhost:8080")
    print("")
    input("Presiona ENTER para comenzar las pruebas...")
    test_oauth2_google()
    test_login_manual()
