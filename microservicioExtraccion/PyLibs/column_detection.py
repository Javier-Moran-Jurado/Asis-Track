import re

import cv2
import numpy as np
import pytesseract


def find_firma_position(img_bgr: np.ndarray) -> dict | None:
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    data = pytesseract.image_to_data(
        binary, config="--psm 11 -l eng", output_type=pytesseract.Output.DICT
    )

    best, best_conf = None, -1
    for i, text in enumerate(data["text"]):
        cleaned = text.strip().lower()
        if not re.search(r"f?irm", cleaned) or len(cleaned) < 3:
            continue
        conf = int(data["conf"][i])
        if conf < 20 or conf <= best_conf:
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
            print(f"  ↷ Encabezado combinado '{text.strip()}' → x ajustado a {tx}")

        best_conf = conf
        best = {
            "x": tx,
            "y": ty,
            "w": tw,
            "h": th,
            "cx": tx + tw // 2,
            "cy": ty + th // 2,
            "text": text.strip(),
            "conf": conf,
        }

    return best


def detect_table_cells(img_bgr: np.ndarray) -> list[dict]:
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

    print(f"  Detectadas {len(cells)} celdas rectangulares")
    return cells


def find_colliding_cell(cells: list[dict], firma: dict) -> dict | None:
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
        print("  No se encontro celda que colisione con 'Firma'")
        return None

    containing.sort(key=lambda c: c["w"] * c["h"])
    best = containing[0]
    print(f"  Celda firma: x={best['x']}, y={best['y']}, w={best['w']}, h={best['h']}")
    return best


def find_cell_bounds(img_bgr: np.ndarray, firma: dict) -> dict:
    img_h, img_w = img_bgr.shape[:2]

    cells = detect_table_cells(img_bgr)
    firma_cell = find_colliding_cell(cells, firma)

    if firma_cell is not None:
        x1 = firma_cell["x"] + 2
        x2 = firma_cell["x"] + firma_cell["w"] - 2
        y1 = firma_cell["y"] + firma_cell["h"] + 3
    else:
        print("  Fallback: usando posicion de firma con margen")
        x1 = max(0, firma["x"] - 10)
        x2 = min(img_w, firma["x"] + firma["w"] + int(img_w * 0.10))
        y1 = firma["y"] + firma["h"] + 3

    y2 = img_h
    print(f"  Bounds -> x=[{x1},{x2}] y=[{y1},{y2}]")
    return {"x1": x1, "x2": x2, "y1": y1, "y2": y2}
