import argparse
import base64
import contextlib
import io
import json
import os
import sys
from pathlib import Path

import cv2
import numpy as np
from paddleocr import TextDetection

try:
    from .column_detection import find_cell_bounds, find_firma_position
    from .image_preprocessing import enhance_for_detection, preprocess_for_ocr
    from .output_utils import save_debug, save_signature_crops
    from .row_detection import detect_rows_in_column, refine_rows
    from .signature_boxes import extract_signature_boxes, merge_split_signatures
    from .signature_config import configure_runtime, configure_tesseract
except ImportError:
    from column_detection import find_cell_bounds, find_firma_position
    from image_preprocessing import enhance_for_detection, preprocess_for_ocr
    from output_utils import save_debug, save_signature_crops
    from row_detection import detect_rows_in_column, refine_rows
    from signature_boxes import extract_signature_boxes, merge_split_signatures
    from signature_config import configure_runtime, configure_tesseract

configure_runtime()
configure_tesseract()


def _log(message: str, verbose: bool) -> None:
    if verbose:
        print(message)


def _load_image(image_source) -> tuple[object | None, str]:
    if isinstance(image_source, str):
        image_path = image_source
        img_orig = cv2.imread(image_path)
        return img_orig, os.path.basename(image_path)

    if image_source is None:
        return None, "input"

    if isinstance(image_source, (bytes, bytearray)):
        np_buffer = np.frombuffer(image_source, dtype=np.uint8)
        img_orig = cv2.imdecode(np_buffer, cv2.IMREAD_COLOR)
        return img_orig, "input"

    return image_source, "input"


def extract_firma_column(
    image_source,
    target_width: int = 1800,
    save_debug_img: bool = True,
    debug_dir: str | os.PathLike[str] | None = None,
    verbose: bool = True,
):
    img_orig, image_name = _load_image(image_source)
    _log(f"\n{'-' * 55}", verbose)
    _log(f"Procesando: {image_name}", verbose)

    if img_orig is None:
        _log("  No se pudo leer", verbose)
        return None

    orig_h, orig_w = img_orig.shape[:2]
    scale = target_width / orig_w
    img_orig_scaled = cv2.resize(
        img_orig, (target_width, int(orig_h * scale)), interpolation=cv2.INTER_CUBIC
    )
    img_pre = preprocess_for_ocr(img_orig.copy(), target_width=target_width)

    firma = find_firma_position(img_pre)
    if firma is None:
        _log("  Reintentando con original escalada...", verbose)
        firma = find_firma_position(img_orig_scaled)
    if firma is None:
        _log("  'Firma' no encontrada", verbose)
        return None

    _log(
        f"  '{firma['text']}' pos=({firma['x']},{firma['y']}) conf={firma['conf']}",
        verbose,
    )
    bounds = find_cell_bounds(img_orig_scaled, firma)

    if save_debug_img:
        tag = os.path.splitext(image_name)[0]
        dbg_dir = (
            Path(debug_dir)
            if debug_dir is not None
            else Path(__file__).resolve().parent / "output"
        )
        os.makedirs(dbg_dir, exist_ok=True)
        save_debug(img_pre, firma, bounds, os.path.join(dbg_dir, f"{tag}_debug.jpg"))

    x1, x2 = bounds["x1"], bounds["x2"]
    y1, y2 = bounds["y1"], bounds["y2"]
    if (x2 - x1) < 30:
        _log(f"  Columna angosta ({x2 - x1}px), expandiendo", verbose)
        x2 = min(img_orig_scaled.shape[1], x1 + int(target_width * 0.20))

    firma_crop = img_orig_scaled[y1:y2, x1:x2]
    if firma_crop.size == 0:
        _log("  Recorte vacio", verbose)
        return None

    _log(f"  Recorte final: {firma_crop.shape[1]}x{firma_crop.shape[0]}px", verbose)
    return firma_crop


def extract_signatures(
    image_source,
    base_name: str | None = None,
    target_width: int = 1800,
    output_dir: str | os.PathLike[str] | None = None,
    save_debug_img: bool = True,
    save_overlay: bool = True,
    verbose: bool = True,
) -> dict:
    img_orig, image_name = _load_image(image_source)
    if base_name is None:
        base_name = Path(image_name).stem

    if output_dir is None:
        output_dir = Path(__file__).resolve().parent / "output"

    output_dir = Path(output_dir)
    paddle_out = output_dir / "test_paddle"
    os.makedirs(output_dir, exist_ok=True)
    os.makedirs(paddle_out, exist_ok=True)

    if img_orig is None:
        raise ValueError("No se pudo leer la imagen de entrada")

    firma_col = extract_firma_column(
        img_orig,
        target_width=target_width,
        save_debug_img=save_debug_img,
        debug_dir=output_dir,
        verbose=verbose,
    )
    if firma_col is None:
        return {
            "base_name": base_name,
            "signature_paths": [],
            "output_dir": str(output_dir),
        }

    row_bounds = refine_rows(detect_rows_in_column(firma_col))
    enhanced = enhance_for_detection(firma_col)
    final_signature_boxes = extract_signature_boxes(
        firma_col=firma_col, enhanced=enhanced, row_bounds=row_bounds
    )
    final_signature_boxes = merge_split_signatures(final_signature_boxes)

    out_img, crop_paths = save_signature_crops(
        base_name,
        firma_col,
        final_signature_boxes,
        output_dir=output_dir,
    )

    overlay_path = None
    if save_overlay:
        overlay_path = str(paddle_out / f"{base_name}.jpg")
        cv2.imwrite(overlay_path, out_img)

    return {
        "base_name": base_name,
        "output_dir": str(output_dir),
        "overlay_path": overlay_path,
        "signature_paths": crop_paths,
        "signature_count": len(crop_paths),
    }


def main():
    parser = argparse.ArgumentParser(description="Extractor parametrizable de firmas")
    parser.add_argument("--image-path", help="Ruta de la imagen de entrada")
    parser.add_argument(
        "--image-base64",
        help="Imagen codificada en base64. Usa '-' para leerla desde stdin.",
    )
    parser.add_argument("--output-dir", help="Directorio de salida", default=None)
    parser.add_argument(
        "--base-name", help="Nombre base para los archivos de salida", default=None
    )
    parser.add_argument("--target-width", type=int, default=1800)
    parser.add_argument("--no-debug", action="store_true")
    parser.add_argument("--no-overlay", action="store_true")
    parser.add_argument(
        "--crop-coordinates",
        help="Coordenadas para recorte manual en formato x,y,w,h",
        default=None,
    )
    args = parser.parse_args()

    if args.image_path or args.image_base64:
        try:
            if args.image_path:
                image_source = args.image_path
            else:
                image_b64 = (
                    sys.stdin.read() if args.image_base64 == "-" else args.image_base64
                )
                image_source = base64.b64decode(image_b64)

            if args.crop_coordinates:
                x, y, w, h = map(int, args.crop_coordinates.split(","))
                img_orig, _ = _load_image(image_source)
                if img_orig is None:
                    raise ValueError(
                        "No se pudo leer la imagen de entrada para recortar"
                    )

                crop = img_orig[y : y + h, x : x + w]
                if crop.size == 0:
                    raise ValueError("El recorte resulto vacio")

                out_dir_path = (
                    Path(args.output_dir)
                    if args.output_dir
                    else Path(__file__).resolve().parent / "output"
                )
                os.makedirs(out_dir_path, exist_ok=True)

                base = args.base_name if args.base_name else "custom_crop"
                out_path = out_dir_path / f"{base}.png"
                cv2.imwrite(str(out_path), crop)

                result = {
                    "base_name": base,
                    "output_dir": str(out_dir_path),
                    "signature_paths": [str(out_path)],
                    "signature_count": 1,
                }
                print(json.dumps(result, ensure_ascii=False))
                return 0

            # Fuerza salida limpia en stdout para integración con Java:
            # solo se imprime el JSON final.
            with contextlib.redirect_stdout(io.StringIO()):
                result = extract_signatures(
                    image_source=image_source,
                    base_name=args.base_name,
                    target_width=args.target_width,
                    output_dir=args.output_dir,
                    save_debug_img=not args.no_debug,
                    save_overlay=not args.no_overlay,
                    verbose=False,
                )
            print(json.dumps(result, ensure_ascii=False))
            return 0
        except Exception as exc:
            error_payload = {"error": str(exc), "signature_paths": []}
            print(json.dumps(error_payload, ensure_ascii=False))
            return 1

    script_dir = os.path.dirname(os.path.abspath(__file__))
    test_dir = os.path.join(script_dir, "..", "testImages")
    out_dir = os.path.join(script_dir, "output")
    cols_dir = os.path.join(script_dir, "cols")
    paddle_out = os.path.join(out_dir, "test_paddle")

    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(cols_dir, exist_ok=True)
    os.makedirs(paddle_out, exist_ok=True)

    image_paths = []
    for i in range(1, 7):
        path = os.path.join(test_dir, f"test{i}.jpg")
        if os.path.exists(path):
            image_paths.append(path)

    try:
        paddle_model = TextDetection(
            thresh=0.01, box_thresh=0.02, unclip_ratio=2.5, limit_side_len=2560
        )
        _ = paddle_model

        for path in image_paths:
            base_name = os.path.basename(path)
            print(f"\n{'-' * 55}\nProcesando: {path}")
            firma_col = extract_firma_column(path)
            if firma_col is None:
                continue

            row_bounds = refine_rows(detect_rows_in_column(firma_col))
            enhanced = enhance_for_detection(firma_col)
            final_signature_boxes = extract_signature_boxes(
                firma_col=firma_col, enhanced=enhanced, row_bounds=row_bounds
            )
            final_signature_boxes = merge_split_signatures(final_signature_boxes)

            out_img, _ = save_signature_crops(
                base_name, firma_col, final_signature_boxes, output_dir=out_dir
            )
            cv2.imwrite(os.path.join(paddle_out, base_name), out_img)
            print(f"  Encontradas {len(final_signature_boxes)} firmas")
    except Exception as e:
        print(f"\nError al procesar: {e}")
        import traceback

        traceback.print_exc()
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
