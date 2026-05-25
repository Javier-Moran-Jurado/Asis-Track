import base64
import os
import sys
import tempfile
import uuid
from pathlib import Path

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse

# Agregar PyLibs al path para imports
sys.path.insert(0, str(Path(__file__).resolve().parent / "PyLibs"))

from SignatureExtractor import extract_signatures

app = FastAPI(title="Microservicio de Extracción de Firmas", version="1.0.0")


@app.get("/health")
def health():
    return {"status": "ok", "service": "extraccion-firmas"}


@app.post("/extract")
async def extract(file: UploadFile = File(...)):
    """
    Recibe una imagen (JPG/PNG/PDF convertido) y devuelve las firmas extraídas
    como array de objetos con base64.
    """
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Archivo vacío")

    base_name = str(uuid.uuid4())
    output_dir = Path(tempfile.gettempdir()) / "extraccion" / base_name
    output_dir.mkdir(parents=True, exist_ok=True)

    try:
        result = extract_signatures(
            image_source=contents,
            base_name=base_name,
            target_width=1800,
            output_dir=output_dir,
            save_debug_img=False,
            save_overlay=False,
            verbose=False,
        )

        signatures = []
        for path in result.get("signature_paths", []):
            path_obj = Path(path)
            if path_obj.exists():
                with open(path_obj, "rb") as f:
                    b64 = base64.b64encode(f.read()).decode("utf-8")
                signatures.append({
                    "filename": path_obj.name,
                    "base64": b64,
                })

        return {
            "base_name": result.get("base_name"),
            "count": len(signatures),
            "signatures": signatures,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error extrayendo firmas: {str(e)}")

    finally:
        # Limpieza de archivos temporales
        import shutil
        if output_dir.exists():
            shutil.rmtree(output_dir, ignore_errors=True)


@app.post("/crop")
async def crop(
    file: UploadFile = File(...),
    x: int = 0,
    y: int = 0,
    w: int = 0,
    h: int = 0,
):
    """
    Recibe una imagen y coordenadas x,y,w,h y devuelve el recorte como base64.
    """
    if w <= 0 or h <= 0:
        raise HTTPException(status_code=400, detail="w y h deben ser mayores a 0")

    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Archivo vacío")

    import cv2
    import numpy as np

    np_buffer = np.frombuffer(contents, dtype=np.uint8)
    img = cv2.imdecode(np_buffer, cv2.IMREAD_COLOR)
    if img is None:
        raise HTTPException(status_code=400, detail="No se pudo decodificar la imagen")

    crop_img = img[y : y + h, x : x + w]
    if crop_img.size == 0:
        raise HTTPException(status_code=400, detail="El recorte resultó vacío")

    _, encoded = cv2.imencode(".png", crop_img)
    b64 = base64.b64encode(encoded.tobytes()).decode("utf-8")

    return {
        "filename": "crop.png",
        "base64": b64,
    }
