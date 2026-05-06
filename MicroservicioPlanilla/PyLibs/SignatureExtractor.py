import os

import cv2
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


def extract_firma_column(
    img_path: str, target_width: int = 1800, save_debug_img: bool = True
):
    print(f"\n{'-' * 55}")
    print(f"Procesando: {img_path}")

    img_orig = cv2.imread(img_path)
    if img_orig is None:
        print("  No se pudo leer")
        return None

    orig_h, orig_w = img_orig.shape[:2]
    scale = target_width / orig_w
    img_orig_scaled = cv2.resize(
        img_orig, (target_width, int(orig_h * scale)), interpolation=cv2.INTER_CUBIC
    )
    img_pre = preprocess_for_ocr(img_orig.copy(), target_width=target_width)

    firma = find_firma_position(img_pre)
    if firma is None:
        print("  Reintentando con original escalada...")
        firma = find_firma_position(img_orig_scaled)
    if firma is None:
        print("  'Firma' no encontrada")
        return None

    print(f"  '{firma['text']}' pos=({firma['x']},{firma['y']}) conf={firma['conf']}")
    bounds = find_cell_bounds(img_orig_scaled, firma)

    if save_debug_img:
        tag = os.path.splitext(os.path.basename(img_path))[0]
        dbg_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
        os.makedirs(dbg_dir, exist_ok=True)
        save_debug(img_pre, firma, bounds, os.path.join(dbg_dir, f"{tag}_debug.jpg"))

    x1, x2 = bounds["x1"], bounds["x2"]
    y1, y2 = bounds["y1"], bounds["y2"]
    if (x2 - x1) < 30:
        print(f"  Columna angosta ({x2 - x1}px), expandiendo")
        x2 = min(img_orig_scaled.shape[1], x1 + int(target_width * 0.20))

    firma_crop = img_orig_scaled[y1:y2, x1:x2]
    if firma_crop.size == 0:
        print("  Recorte vacio")
        return None

    print(f"  Recorte final: {firma_crop.shape[1]}x{firma_crop.shape[0]}px")
    return firma_crop


def main():
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

            out_img = save_signature_crops(base_name, firma_col, final_signature_boxes)
            cv2.imwrite(os.path.join(paddle_out, base_name), out_img)
            print(f"  Encontradas {len(final_signature_boxes)} firmas")
    except Exception as e:
        print(f"\nError al procesar: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    main()
