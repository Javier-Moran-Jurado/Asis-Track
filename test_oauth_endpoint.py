#!/usr/bin/env python3
"""
Script para probar el endpoint OAuth2 de Google del backend Asis-Track.

Este script realiza dos pruebas:
1. Prueba con token invalido -> espera 400 Bad Request
2. (Opcional) Prueba con token real de Google -> el usuario debe obtenerlo manualmente
"""

import json
import requests
import os

BACKEND_URL = "http://localhost:8080/api/v1/auth/oauth2/google"

def test_token_invalido():
    """Prueba 1: Enviar un token JWT sinteticamente invalido."""
    print("=" * 60)
    print("PRUEBA 1: Token invalido (firma falsa)")
    print("=" * 60)

    fake_token = (
        "eyJhbGciOiJSUzI1NiIsImtpZCI6ImZha2UiLCJ0eXAiOiJKV1QifQ."
        "eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiIxMjM0NTY3ODktYWJjLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwiYXVkIjoiMTIzNDU2Nzg5LWFiYy5hcHBzLmdvb2dsZXVzZXJjb250ZW50LmNvbSIsInN1YiI6IjEyMzQ1Njc4OTAiLCJlbWFpbCI6InRlc3RAdWNldmEuZWR1LmNvIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsIm5hbWUiOiJUZXN0IFVzZXIiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tLyIsImdpdmVuX25hbWUiOiJUZXN0IiwiZmFtaWx5X25hbWUiOiJVc2VyIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjE3MDAwMDM2MDB9."
        "invalid_signature"
    )

    payload = {"idToken": fake_token}
    headers = {"Content-Type": "application/json"}

    try:
        response = requests.post(BACKEND_URL, json=payload, headers=headers, timeout=15)
    except requests.exceptions.ConnectionError:
        print(f"\n[ERROR] No se pudo conectar al backend en {BACKEND_URL}")
        print("   Asegurate de que el contenedor 'usuarioservice' este corriendo.")
        return False

    print(f"\n[Request]")
    print(f"   POST {BACKEND_URL}")
    print(f"   Body: {{'idToken': '...{fake_token[-20:]}'}}")

    print(f"\n[Response]")
    print(f"   Status: {response.status_code} {response.reason}")

    try:
        data = response.json()
        mensaje = data.get("message", data.get("error", response.text)) if data else response.text
    except json.JSONDecodeError:
        mensaje = response.text

    print(f"   Body: {mensaje}")

    if response.status_code == 400:
        print("\n[OK] PRUEBA 1 PASADA: El endpoint rechazo correctamente el token falso.")
        return True
    else:
        print("\n[AVISO] PRUEBA 1: Respuesta inesperada (revisa arriba)")
        return False


def test_token_real(id_token: str) -> bool:
    """Prueba 2: Enviar un idToken real obtenido de Google."""
    print("\n" + "=" * 60)
    print("PRUEBA 2: Token real de Google")
    print("=" * 60)

    payload = {"idToken": id_token}
    headers = {"Content-Type": "application/json"}

    try:
        response = requests.post(BACKEND_URL, json=payload, headers=headers, timeout=15)
    except requests.exceptions.ConnectionError:
        print(f"\n[ERROR] No se pudo conectar al backend.")
        return False

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
        print(f"   access_token : ...{data.get('access_token', '')[-30:]}")
        print(f"   refresh_token: ...{data.get('refresh_token', '')[-30:]}")
        return True
    elif response.status_code in (400, 401, 403):
        print(f"\n[ACCESO DENEGADO]")
        mensaje = data.get("message", data.get("error", "Sin detalle")) if data else "Sin detalle"
        print(f"   Motivo: {mensaje}")
    else:
        print(f"\n[ERROR INESPERADO]")
        print(f"   Body: {response.text[:500]}")

    return False


def main():
    print("\n" + "=" * 60)
    print("PRUEBA DE ENDPOINT /api/v1/auth/oauth2/google")
    print("=" * 60)

    # Prueba 1: Token invalido
    paso1 = test_token_invalido()

    # Prueba 2: Token real (opcional)
    print("\n" + "-" * 60)
    print("Prueba con idToken REAL de Google")
    print("-" * 60)
    print("\nPara obtener un idToken real:")
    print("1. Ve a https://developers.google.com/oauthplayground")
    print("2. En 'Select & authorize APIs', escribe: openid email profile")
    print("3. Presiona 'Authorize APIs'")
    print("4. Inicia sesion con tu cuenta @uceva.edu.co")
    print("5. Presiona 'Exchange authorization code for tokens'")
    print("6. Copia el valor de 'id_token'")
    print("\nLuego ejecuta este script con la variable de entorno:")
    print("   $env:GOOGLE_ID_TOKEN='eyJhbGciOi...'; python test_oauth_endpoint.py")

    id_token = os.environ.get("GOOGLE_ID_TOKEN", "").strip()

    if id_token:
        paso2 = test_token_real(id_token)
    else:
        print("\n[OMITIDO] No se proporciono GOOGLE_ID_TOKEN.")
        paso2 = None

    print("\n" + "=" * 60)
    print("RESUMEN")
    print("=" * 60)
    print(f"Prueba 1 (token invalido): {'PASO' if paso1 else 'FALLO'}")
    if paso2 is not None:
        print(f"Prueba 2 (token real)    : {'PASO' if paso2 else 'FALLO'}")
    else:
        print("Prueba 2 (token real)    : OMITIDO")
    print("=" * 60)


if __name__ == "__main__":
    main()
