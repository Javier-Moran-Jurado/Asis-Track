#!/usr/bin/env python3
"""
Script para probar el endpoint OAuth2 de Google del backend Asis-Track.

Flujo:
1. Obtiene un idToken REAL de Google usando OAuth2 (flujo local).
2. Lo envia al backend para validacion.
3. Muestra el resultado.

Requiere: iniciar sesion con una cuenta @uceva.edu.co en el navegador.
"""

import json
import os
import sys
import requests

# Evita que oauthlib lance excepcion cuando Google cambia scopes a formato canonico
os.environ["OAUTHLIB_RELAX_TOKEN_SCOPE"] = "1"

from google_auth_oauthlib.flow import InstalledAppFlow

# Credenciales OAuth2 de la aplicacion WEB de Asis-Track
CLIENT_ID = "google-client-id"
CLIENT_SECRET = "google-client-secret"

SCOPES = ["openid", "email", "profile"]
BACKEND_URL = "http://localhost:8080/api/v1/auth/oauth2/google"


def obtener_id_token():
    client_config = {
        "installed": {
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET,
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
            "redirect_uris": ["http://localhost"]
        }
    }

    flow = InstalledAppFlow.from_client_config(client_config, SCOPES)

    print("=" * 60)
    print("AUTENTICACION CON GOOGLE")
    print("=" * 60)
    print("\nSe iniciara un servidor local para recibir el callback.")
    print("Si tu navegador no se abre automaticamente, copia la URL")
    print("que aparecera a continuacion y abrela manualmente.\n")
    print("IMPORTANTE: Inicia sesion con tu correo @uceva.edu.co\n")

    try:
        # open_browser=False para que no intente abrir el navegador automaticamente
        credentials = flow.run_local_server(port=8089, open_browser=False)
    except Warning as w:
        # Google puede cambiar los scopes a sus URLs canonicas; eso no es un error real.
        print(f"\n[Aviso] {w}")
        print("Google cambio los scopes a formato canonico (es normal). Continuando...")
        credentials = flow.credentials
    except Exception as e:
        # Si el error es "Scope has changed", las credenciales aun pueden estar disponibles
        error_msg = str(e)
        if "Scope has changed" in error_msg:
            print(f"\n[Aviso] {error_msg}")
            print("Google cambio los scopes a formato canonico (es normal). Continuando...")
            try:
                credentials = flow.credentials
            except AttributeError:
                print("\nNo se pudieron obtener las credenciales automaticamente.")
                print("Como la autenticacion en el navegador fue exitosa,")
                print("usa el metodo manual con el Google OAuth Playground.")
                print("\nInstrucciones:")
                print("1. Ve a https://developers.google.com/oauthplayground")
                print("2. Selecciona scope: openid email profile")
                print("3. Autoriza con tu cuenta @uceva.edu.co")
                print("4. Intercambia el code por tokens")
                print("5. Copia el id_token y ejecuta:")
                print("   $env:GOOGLE_ID_TOKEN='eyJ...'; python test_oauth_endpoint.py")
                sys.exit(1)
        else:
            print(f"\n[Error] {e}")
            print("\nPosibles causas:")
            print("1. El redirect URI http://localhost:8089 no esta autorizado en Google Cloud Console.")
            print("   Ve a https://console.cloud.google.com/apis/credentials")
            print("   Edita tu Client ID Web y agrega: http://localhost:8089")
            print("2. El puerto 8089 esta ocupado.")
            sys.exit(1)

    id_token = getattr(credentials, "id_token", None)
    if not id_token:
        print("\nNo se pudo obtener el idToken.")
        print("Como la autenticacion en el navegador fue exitosa,")
        print("usa el metodo manual con el Google OAuth Playground.")
        sys.exit(1)

    print(f"\n[OK] idToken obtenido exitosamente.")
    print(f"   Longitud: {len(id_token)} caracteres")
    return id_token


def probar_endpoint(id_token):
    print("\n" + "=" * 60)
    print("PRUEBA DEL ENDPOINT /api/v1/auth/oauth2/google")
    print("=" * 60)

    payload = {"idToken": id_token}
    headers = {"Content-Type": "application/json"}

    try:
        response = requests.post(BACKEND_URL, json=payload, headers=headers, timeout=15)
    except requests.exceptions.ConnectionError:
        print(f"\n[ERROR] No se pudo conectar al backend en {BACKEND_URL}")
        print("   Asegurate de que el contenedor 'usuarioservice' este corriendo.")
        print("   Ejecuta: docker compose up -d usuarioservice")
        sys.exit(1)
    except Exception as e:
        print(f"\n[ERROR] {e}")
        sys.exit(1)

    print(f"\n[Request]")
    print(f"   POST {BACKEND_URL}")
    print(f"   Body: {{'idToken': '...{id_token[-20:]}'}}")

    print(f"\n[Response]")
    print(f"   Status: {response.status_code} {response.reason}")

    try:
        data = response.json()
    except json.JSONDecodeError:
        data = None

    if response.status_code == 200:
        print(f"\n[EXITO] LOGIN CON GOOGLE FUNCIONA!")
        print(f"   access_token : {data.get('access_token', '')}")
        print(f"   refresh_token: {data.get('refresh_token', '')}")
    elif response.status_code in (400, 401, 403):
        print(f"\n[ACCESO DENEGADO]")
        mensaje = data.get("message", data.get("error", "Sin detalle")) if data else "Sin detalle"
        print(f"   Motivo: {mensaje}")
    else:
        print(f"\n[ERROR INESPERADO]")
        print(f"   Body: {response.text[:500]}")

    return response.status_code == 200


def main():
    print("\n" + "=" * 60)
    print("PRUEBA DE OAUTH2 GOOGLE - ASIS-TRACK")
    print("=" * 60)
    print("\nEste script va a:")
    print("1. Abrir una URL de Google en tu navegador")
    print("2. Pedirte que inicies sesion con tu cuenta @uceva.edu.co")
    print("3. Enviar el idToken al backend para validacion")
    print("\nPresiona ENTER para continuar...")
    try:
        input()
    except EOFError:
        pass  # Entorno no interactivo

    id_token = obtener_id_token()
    exito = probar_endpoint(id_token)

    print("\n" + "=" * 60)
    if exito:
        print("RESULTADO: Login con Google funcionando correctamente")
    else:
        print("RESULTADO: El login fue rechazado (revisa el motivo arriba)")
    print("=" * 60)


if __name__ == "__main__":
    main()
