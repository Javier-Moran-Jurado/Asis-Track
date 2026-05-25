import logging
import re

import cv2
import numpy as np
import pytesseract

logger = logging.getLogger(__name__)

FIRMA_REGEX = re.compile(r"f[ií]?[r]?m?a?", re.IGNORECASE)

PSM_MODES = [11, 6, 3]


def _preprocess_for_tesseract(img_bgr: np.ndarray) -> list[np.ndarray]:
    """Genera múltiples versiones preprocesadas para maximizar detección de texto."""
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)

    h, w = gray.shape
    if w < 600:
        gray = cv2.resize(gray, (w * 2, h * 2), interpolation=cv2.INTER_CUBIC)

    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    gray_clahe = clahe.apply(gray)

    _, binary_otsu = cv2.threshold(gray_clahe, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    _, binary_inv = cv2.threshold(gray_clahe, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

    sharpened = cv2.GaussianBlur(gray_clahe, (0, 0), 1.5)
    sharpened = cv2.addWeighted(gray_clahe, 1.5, sharpened, -0.5, 0)
    _, binary_sharp = cv2.threshold(sharpened, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    return [binary_otsu, binary_inv, binary_sharp]


def _run_tesseract(img: np.ndarray, psm: int) -> dict:
    return pytesseract.image_to_data(
        img, config=f"--psm {psm} -l spa+eng", output_type=pytesseract.Output.DICT
    )


def _extract_best_firma(data: dict, best: dict | None, best_conf: int) -> tuple[dict | None, int]:
    for i, text in enumerate(data["text"]):
        cleaned = text.strip().lower()
        if not cleaned:
            continue

        if not FIRMA_REGEX.search(cleaned) or len(cleaned) < 2:
            continue

        conf = int(data["conf"][i])
        if conf < 15 or conf <= best_conf:
            continue

        tx = data["left"][i]
        ty = data["top"][i]
        tw = data["width"][i]
        th = data["height"][i]

        if "/" in cleaned:
            parts = cleaned.split("/")
            firma_part = parts[-1]
            full_chars = sum(len(p) for p in parts)
            if full_chars > 0:
                firma_ratio = len(firma_part) / full_chars
                tx = tx + int(tw * (1 - firma_ratio))
                tw = int(tw * firma_ratio)

        best_conf = conf
        best = {
            "x": tx, "y": ty, "w": tw, "h": th,
            "cx": tx + tw // 2, "cy": ty + th // 2,
            "text": text.strip(), "conf": conf,
        }
        logger.info(f"[Tesseract] Match candidato: '{text.strip()}' conf={conf} pos=({tx},{ty})")

    return best, best_conf


def find_firma_position_tesseract(img_bgr: np.ndarray, verbose: bool = False) -> dict | None:
    """Busca 'Firma' usando Tesseract con múltiples preprocesamientos y modos PSM."""
    preprocessed_images = _preprocess_for_tesseract(img_bgr)

    best, best_conf = None, -1

    for psm in PSM_MODES:
        if best is not None and best_conf >= 60:
            break

        for idx, proc_img in enumerate(preprocessed_images):
            if best is not None and best_conf >= 60:
                break

            data = _run_tesseract(proc_img, psm)
            all_texts = [t.strip() for t in data["text"] if t.strip()]

            if idx == 0:
                logger.info(f"[Tesseract psm={psm}] Detectó {len(all_texts)} palabras: {all_texts[:15]}")

            best, best_conf = _extract_best_firma(data, best, best_conf)

    if best is None:
        logger.warning(f"[Tesseract] No se encontró 'Firma' tras probar {len(PSM_MODES)} modos PSM y {len(preprocessed_images)} preprocesamientos")
    else:
        logger.info(f"[Tesseract] Seleccionado: '{best['text']}' conf={best['conf']} (psm=óptimo)")

    return best


def find_firma_position(img_bgr: np.ndarray, verbose: bool = False) -> dict | None:
    """Busca 'Firma' usando Tesseract OCR con múltiples estrategias."""
    return find_firma_position_tesseract(img_bgr, verbose=verbose)


def detect_table_cells(img_bgr: np.ndarray, verbose: bool = False) -> list[dict]:
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    img_h, img_w = gray.shape[:2]

    binary = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY_INV, 15, 10
    )

    h_len = max(int(img_w * 0.05), 30)
    h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (h_len, 1))
    h_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, h_kernel)

    v_len = max(int(img_h * 0.03), 20)
    v_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, v_len))
    v_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, v_kernel)

    grid = cv2.add(h_lines, v_lines)
    close_k = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
    grid = cv2.dilate(grid, close_k, iterations=2)

    contours, _ = cv2.findContours(grid, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    min_area = img_h * img_w * 0.0005
    max_area = img_h * img_w * 0.90

    cells = []
    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area < min_area or area > max_area:
            continue
        x, y, w, h = cv2.boundingRect(cnt)
        if w < 20 or h < 15:
            continue
        cells.append({"x": x, "y": y, "w": w, "h": h})

    if verbose:
        print(f"  Detectadas {len(cells)} celdas rectangulares")
    return cells


def find_colliding_cell(cells: list[dict], firma: dict, verbose: bool = False) -> dict | None:
    cx, cy = firma["cx"], firma["cy"]

    containing = []
    for cell in cells:
        x1, y1 = cell["x"], cell["y"]
        x2, y2 = x1 + cell["w"], y1 + cell["h"]
        if x1 <= cx <= x2 and y1 <= cy <= y2:
            containing.append(cell)

    if not containing:
        fx1, fy1 = firma["x"], firma["y"]
        fx2, fy2 = fx1 + firma["w"], fy1 + firma["h"]
        for cell in cells:
            cx1, cy1 = cell["x"], cell["y"]
            cx2, cy2 = cx1 + cell["w"], cy1 + cell["h"]
            if cx1 < fx2 and cx2 > fx1 and cy1 < fy2 and cy2 > fy1:
                containing.append(cell)

    if not containing:
        if verbose:
            print("  No se encontro celda que colisione con 'Firma'")
        return None

    containing.sort(key=lambda c: c["w"] * c["h"])
    best = containing[0]
    if verbose:
        print(f"  Celda firma: x={best['x']}, y={best['y']}, w={best['w']}, h={best['h']}")
    return best


def find_cell_bounds(img_bgr: np.ndarray, firma: dict, verbose: bool = False) -> dict:
    img_h, img_w = img_bgr.shape[:2]

    cells = detect_table_cells(img_bgr, verbose=verbose)
    firma_cell = find_colliding_cell(cells, firma, verbose=verbose)

    if firma_cell is not None:
        x1 = firma_cell["x"] + 2
        x2 = firma_cell["x"] + firma_cell["w"] - 2
        y1 = firma_cell["y"] + firma_cell["h"] + 3
    else:
        if verbose:
            print("  Fallback: usando posicion de firma con margen")
        x1 = max(0, firma["x"] - 10)
        x2 = min(img_w, firma["x"] + firma["w"] + int(img_w * 0.10))
        y1 = firma["y"] + firma["h"] + 3

    y2 = img_h
    if verbose:
        print(f"  Bounds -> x=[{x1},{x2}] y=[{y1},{y2}]")
    return {"x1": x1, "x2": x2, "y1": y1, "y2": y2}
