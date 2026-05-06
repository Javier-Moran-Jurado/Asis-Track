from os import environ
environ['HF_TOKEN'] = environ.get('HF_TOKEN')
environ['FLAGS_use_mkldnn'] = '0'
environ['MKLDNN_VERBOSE'] = '0'
environ['FLAGS_enable_pir_api'] = '0'
import cv2
import numpy as np
import pytesseract
import re
import os
from paddleocr import TextDetection

# Configurar ruta de Tesseract en Windows
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

def preprocess_for_paddle(img_path: str) -> np.ndarray:
    """
    Preprocesa una imagen de formulario manuscrito para mejorar
    la detección de PaddleOCR.
    Retorna la imagen en BGR lista para pasarle al modelo.
    """
    img = cv2.imread(img_path)

    h, w = img.shape[:2]
    if w < 1500:
        scale = 1500 / w
        img = cv2.resize(img, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # 1. Binarización adaptativa (maneja sombras y variaciones de fondo)
    binary = cv2.adaptiveThreshold(
        gray, 255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        blockSize=31,   # bloque grande → tolera gradientes de iluminación
        C=25            # constante de sustracción; subir si quedan manchas
    )

    # Paddle espera BGR, así que volvemos a 3 canales
    result = cv2.cvtColor(binary, cv2.COLOR_GRAY2BGR)
    return result





def preprocess_for_ocr(img: np.ndarray, target_width: int = 1800) -> np.ndarray:
    h, w = img.shape[:2]
    if w != target_width:
        scale = target_width / w
        img = cv2.resize(img, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(16, 16))
    gray = clahe.apply(gray)
    gray = cv2.bilateralFilter(gray, d=9, sigmaColor=45, sigmaSpace=45)
    binary = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY, blockSize=31, C=18
    )
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2, 2))
    binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, k)
    binary = cv2.dilate(binary, k, iterations=1)
    return cv2.cvtColor(binary, cv2.COLOR_GRAY2BGR)


# ── Fix principal: manejar "COMPLETO/FIRMA" ajustando x ───────────────────────

def find_firma_position(img_bgr: np.ndarray) -> dict | None:
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    data = pytesseract.image_to_data(
        binary, config="--psm 11 -l eng",
        output_type=pytesseract.Output.DICT
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

        # Caso "COMPLETO/FIRMA": ajustar x al inicio de la parte "firma"
        # en vez de descartar, estimamos la posición proporcional al texto
        if "/" in cleaned:
            parts = cleaned.split("/")
            firma_part = parts[-1]          # "firma"
            full_chars = sum(len(p) for p in parts)
            if full_chars > 0:
                firma_ratio = len(firma_part) / full_chars
                tx = tx + int(tw * (1 - firma_ratio))
                tw = int(tw * firma_ratio)
            print(f"  ↷ Encabezado combinado '{text.strip()}' → x ajustado a {tx}")

        best_conf = conf
        best = {
            "x": tx, "y": ty, "w": tw, "h": th,
            "cx": tx + tw // 2,
            "cy": ty + th // 2,
            "text": text.strip(), "conf": conf,
        }

    return best


# ── Detección de celdas rectangulares y colisión con "Firma" ────────────────────

def detect_table_cells(img_bgr: np.ndarray) -> list[dict]:
    """
    Detecta celdas rectangulares de la tabla usando detección morfológica
    de líneas horizontales/verticales + análisis de contornos.
    """
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    img_h, img_w = gray.shape[:2]

    binary = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_MEAN_C,
        cv2.THRESH_BINARY_INV, 15, 10
    )

    # Líneas horizontales (mín 5% del ancho)
    h_len = max(int(img_w * 0.05), 30)
    h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (h_len, 1))
    h_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, h_kernel)

    # Líneas verticales (mín 3% de la altura)
    v_len = max(int(img_h * 0.03), 20)
    v_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, v_len))
    v_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, v_kernel)

    # Combinar para formar la grilla
    grid = cv2.add(h_lines, v_lines)

    # Cerrar huecos pequeños en intersecciones
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
    """
    Encuentra la celda rectangular que colisiona con la posición del texto 'Firma'.
    Retorna la celda más pequeña que contiene el centro de 'Firma'.
    """
    cx, cy = firma["cx"], firma["cy"]

    # Paso 1: celdas que contienen el centro de firma
    containing = []
    for cell in cells:
        x1, y1 = cell["x"], cell["y"]
        x2, y2 = x1 + cell["w"], y1 + cell["h"]
        if x1 <= cx <= x2 and y1 <= cy <= y2:
            containing.append(cell)

    # Paso 2 fallback: celdas que se solapan con el bbox de firma
    if not containing:
        fx1, fy1 = firma["x"], firma["y"]
        fx2, fy2 = fx1 + firma["w"], fy1 + firma["h"]
        for cell in cells:
            cx1, cy1 = cell["x"], cell["y"]
            cx2, cy2 = cx1 + cell["w"], cy1 + cell["h"]
            if cx1 < fx2 and cx2 > fx1 and cy1 < fy2 and cy2 > fy1:
                containing.append(cell)

    if not containing:
        print("  ⚠ No se encontró celda que colisione con 'Firma'")
        return None

    # La más pequeña = celda de encabezado específica, no toda la tabla
    containing.sort(key=lambda c: c["w"] * c["h"])
    best = containing[0]
    print(f"  ✓ Celda firma: x={best['x']}, y={best['y']}, "
          f"w={best['w']}, h={best['h']}")
    return best


def find_cell_bounds(img_bgr: np.ndarray, firma: dict) -> dict:
    """
    Detecta figuras rectangulares, encuentra la que colisiona con 'Firma',
    y retorna los límites del crop:
      x1..x2 = ancho de columna según el rectángulo detectado
      y1     = justo debajo de la celda de encabezado
      y2     = fondo de la imagen
    """
    img_h, img_w = img_bgr.shape[:2]

    cells = detect_table_cells(img_bgr)
    firma_cell = find_colliding_cell(cells, firma)

    if firma_cell is not None:
        x1 = firma_cell["x"] + 2
        x2 = firma_cell["x"] + firma_cell["w"] - 2
        y1 = firma_cell["y"] + firma_cell["h"] + 3
    else:
        # Fallback: usar posición de firma con margen
        print("  ↺ Fallback: usando posición de firma con margen")
        x1 = max(0, firma["x"] - 10)
        x2 = min(img_w, firma["x"] + firma["w"] + int(img_w * 0.10))
        y1 = firma["y"] + firma["h"] + 3

    y2 = img_h  # siempre recortar hasta el fondo

    print(f"  Bounds → x=[{x1},{x2}] y=[{y1},{y2}]")
    return {"x1": x1, "x2": x2, "y1": y1, "y2": y2}


def save_debug(img_bgr, firma, bounds, path):
    dbg = img_bgr.copy()
    cv2.rectangle(dbg,
                  (firma["x"], firma["y"]),
                  (firma["x"] + firma["w"], firma["y"] + firma["h"]),
                  (0, 255, 0), 2)
    cv2.rectangle(dbg,
                  (bounds["x1"], bounds["y1"]),
                  (bounds["x2"], bounds["y2"]),
                  (0, 0, 255), 2)
    cv2.imwrite(path, dbg)


# ── Pipeline ───────────────────────────────────────────────────────────────────

def extract_firma_column(img_path: str, target_width: int = 1800,
                         save_debug_img: bool = True) -> np.ndarray | None:
    print(f"\n{'─'*55}")
    print(f"Procesando: {img_path}")

    img_orig = cv2.imread(img_path)
    if img_orig is None:
        print("  ✗ No se pudo leer"); return None

    orig_h, orig_w = img_orig.shape[:2]
    scale = target_width / orig_w

    # ── Ambas imágenes al MISMO tamaño ────────────────────────────────────────
    img_orig_scaled = cv2.resize(
        img_orig,
        (target_width, int(orig_h * scale)),
        interpolation=cv2.INTER_CUBIC
    )
    img_pre = preprocess_for_ocr(img_orig.copy(), target_width=target_width)

    # ── Detección sobre preprocesada ──────────────────────────────────────────
    firma = find_firma_position(img_pre)
    if firma is None:
        print("  ↺ Reintentando con original escalada...")
        firma = find_firma_position(img_orig_scaled)

    if firma is None:
        print("  ✗ 'Firma' no encontrada"); return None

    print(f"  ✓ '{firma['text']}' pos=({firma['x']},{firma['y']}) conf={firma['conf']}")

    # ── Detección de celdas sobre ORIGINAL (las líneas se preservan) ────────────
    bounds = find_cell_bounds(img_orig_scaled, firma)

    # ── Debug sobre preprocesada (para verificar detección) ───────────────────
    tag = os.path.splitext(os.path.basename(img_path))[0]
    if save_debug_img:
        dbg_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
        os.makedirs(dbg_dir, exist_ok=True)
        save_debug(img_pre, firma, bounds, os.path.join(dbg_dir, f"{tag}_debug.jpg"))

    x1, x2 = bounds["x1"], bounds["x2"]
    y1, y2 = bounds["y1"], bounds["y2"]

    if (x2 - x1) < 30:
        print(f"  ⚠ Columna angosta ({x2-x1}px), expandiendo")
        x2 = min(img_orig_scaled.shape[1], x1 + int(target_width * 0.20))

    # ── Recorte sobre ORIGINAL escalada (sin filtros) ─────────────────────────
    firma_crop = img_orig_scaled[y1:y2, x1:x2]

    if firma_crop.size == 0:
        print(f"  ✗ Recorte vacío"); return None

    print(f"  ✓ Recorte final: {firma_crop.shape[1]}x{firma_crop.shape[0]}px")
    return firma_crop

# ── Preprocesamiento y filtrado para PaddleOCR ─────────────────────────────────

def enhance_for_detection(img_bgr: np.ndarray) -> np.ndarray:
    """
    Mejora el contraste de la imagen para que PaddleOCR y OpenCV detecten
    trazos manuscritos débiles. Estrategia agresiva:
      1. CLAHE con clip alto para resaltar trazos
      2. Bilateral para suavizar ruido sin perder bordes
    """
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)

    # CLAHE muy agresivo
    clahe = cv2.createCLAHE(clipLimit=4.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)

    # Bilateral para suavizar ruido sin perder bordes
    enhanced = cv2.bilateralFilter(enhanced, d=5, sigmaColor=40, sigmaSpace=40)

    return cv2.cvtColor(enhanced, cv2.COLOR_GRAY2BGR)

def detect_rows_in_column(firma_col: np.ndarray) -> list[tuple[int, int]]:
    """
    Usa proyección horizontal para encontrar las líneas que separan las filas 
    dentro de la columna de firmas.
    Retorna una lista de tuplas (y1, y2) para cada fila.
    """
    img_h, img_w = firma_col.shape[:2]
    gray = cv2.cvtColor(firma_col, cv2.COLOR_BGR2GRAY)
    
    # Binarizar para resaltar líneas (las líneas oscuras se vuelven blancas)
    binary = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 21, 10)
    
    # Encontrar líneas horizontales (deben cubrir al menos 40% del ancho de la columna)
    h_len = max(int(img_w * 0.4), 20)
    h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (h_len, 1))
    h_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, h_kernel)
    
    # Proyectar horizontalmente para encontrar coordenadas Y
    proj = np.sum(h_lines, axis=1)
    
    y_lines = []
    in_line = False
    start_y = 0
    # Umbral de proyección: 30% del ancho
    threshold = 255 * (img_w * 0.3)
    
    for y, val in enumerate(proj):
        if val > threshold:
            if not in_line:
                start_y = y
                in_line = True
        else:
            if in_line:
                center_y = (start_y + y) // 2
                y_lines.append(center_y)
                in_line = False
                
    if in_line:
        y_lines.append((start_y + img_h) // 2)
        
    y_lines = [0] + y_lines + [img_h]
    
    rows = []
    for i in range(len(y_lines) - 1):
        y1 = y_lines[i]
        y2 = y_lines[i+1]
        h = y2 - y1
        if h > 20:  # Ignorar franjas demasiado delgadas que sean ruido
            rows.append((y1, y2))
            
    return rows


def filter_detections(dt_polys: list, img_shape: tuple,
                      min_area: int = 400,
                      min_aspect: float = 0.08,
                      max_aspect: float = 15.0) -> list:
    """
    Filtra las detecciones de PaddleOCR para quedarse solo con
    regiones que parezcan texto manuscrito / firmas:
      - Descarta cajas muy pequeñas (ruido, puntos)
      - Descarta cajas con aspect ratio extremo (líneas de tabla)
      - Descarta cajas que abarcan casi todo el ancho (texto impreso de pie de página)
    """
    img_h, img_w = img_shape[:2]
    filtered = []

    for poly in dt_polys:
        pts = np.array(poly, dtype=np.float64)
        x_min, y_min = pts.min(axis=0)
        x_max, y_max = pts.max(axis=0)
        w = x_max - x_min
        h = y_max - y_min

        if w < 1 or h < 1:
            continue

        area = float(w * h)
        aspect = w / h

        # Descartar detecciones muy pequeñas (ruido, manchas)
        if area < min_area:
            continue

        # Descartar líneas horizontales (aspect ratio muy alto)
        # o líneas verticales (aspect ratio muy bajo)
        if aspect > max_aspect or aspect < min_aspect:
            continue

        # Descartar cajas que cubren >90% del ancho (texto impreso largo)
        if w > img_w * 0.90:
            continue

        # Descartar cajas muy altas y angostas (bordes de tabla)
        if h > img_h * 0.3 and w < 20:
            continue

        filtered.append(poly)

    return filtered


def draw_filtered(img_bgr: np.ndarray, boxes: list, save_path: str):
    """
    Dibuja las cajas filtradas sobre la imagen original y la guarda.
    """
    output = img_bgr.copy()
    for poly in boxes:
        pts = np.array(poly, dtype=np.int32)
        cv2.polylines(output, [pts], isClosed=True,
                      color=(0, 0, 255), thickness=2)
    cv2.imwrite(save_path, output)


# ── Ejecutar ───────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    TEST_DIR = os.path.join(SCRIPT_DIR, "..", "testImages")
    OUT_DIR = os.path.join(SCRIPT_DIR, "output")
    COLS_DIR = os.path.join(SCRIPT_DIR, "cols")

    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(COLS_DIR, exist_ok=True)
    paddle_out = os.path.join(OUT_DIR, "test_paddle")
    os.makedirs(paddle_out, exist_ok=True)
    
    # Crear lista de imágenes
    image_paths = []
    for i in range(1, 7):
        path = os.path.join(TEST_DIR, f"test{i}.jpg")
        if os.path.exists(path):
            image_paths.append(path)
            
    try:
        paddle_model = TextDetection(
            thresh=0.01,
            box_thresh=0.02, 
            unclip_ratio=2.5,
            limit_side_len=2560
        )

        for path in image_paths:
            base_name = os.path.basename(path)
            print(f"\n{'─'*55}\nProcesando: {path}")
            firma_col = extract_firma_column(path)
            
            if firma_col is None:
                continue
                
            # Extraer las filas usando la grilla (líneas horizontales)
            row_bounds = detect_rows_in_column(firma_col)
            
            # Sub-dividir filas altas que probablemente contienen múltiples firmas/nombres
            if len(row_bounds) > 2:
                heights = [y2 - y1 for y1, y2 in row_bounds]
                median_h = np.median(heights)
                refined_rows = []
                for ry1, ry2 in row_bounds:
                    rh = ry2 - ry1
                    if rh > median_h * 1.6:
                        n_parts = round(rh / median_h)
                        part_h = rh / n_parts
                        for j in range(n_parts):
                            sub_y1 = ry1 + int(j * part_h)
                            sub_y2 = ry1 + int((j + 1) * part_h)
                            refined_rows.append((sub_y1, sub_y2))
                    else:
                        refined_rows.append((ry1, ry2))
                row_bounds = refined_rows
            
            # Mejorar contraste para OpenCV
            enhanced = enhance_for_detection(firma_col)
            
            final_signature_boxes = []
            
            # Procesar fila por fila
            for y1, y2 in row_bounds:
                row_h = y2 - y1
                row_w = firma_col.shape[1]
                
                # Imagen de la fila
                row_img = enhanced[y1:y2, 0:row_w]
                gray_row = cv2.cvtColor(row_img, cv2.COLOR_BGR2GRAY)
                
                # Binarizar para encontrar tinta
                binary = cv2.adaptiveThreshold(gray_row, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 21, 10)
                
                # Eliminar restos de líneas horizontales dentro de la fila
                h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (40, 1))
                h_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, h_kernel)
                ink = cv2.subtract(binary, h_lines)
                
                # Dilatar para conectar trazos sueltos de la firma
                kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
                dilated = cv2.dilate(ink, kernel, iterations=2)
                
                contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
                
                if not contours:
                    continue
                    
                # Calcular la cantidad real de tinta en la celda
                ink_pixels = cv2.countNonZero(ink)
                if ink_pixels < 100:  # Volver a un umbral seguro para firmas tenues
                    continue
                    
                # Encontrar el bounding box que agrupa toda la tinta de la firma
                x_min, y_min = row_w, row_h
                x_max, y_max = 0, 0
                
                significant_contours = 0
                total_area_real = 0
                max_contour_area = 0
                
                for cnt in contours:
                    area_real = cv2.contourArea(cnt)
                    x, y, w, h = cv2.boundingRect(cnt)
                    
                    # Ignorar ruido pequeño. Una mancha real de tinta (dilatada) tiene área > 80.
                    if area_real > 80: 
                        significant_contours += 1
                        x_min = min(x_min, x)
                        y_min = min(y_min, y)
                        x_max = max(x_max, x + w)
                        y_max = max(y_max, y + h)
                        total_area_real += area_real
                        max_contour_area = max(max_contour_area, area_real)
                        
                if significant_contours == 0 or x_min >= x_max or y_min >= y_max:
                    continue
                    
                w = x_max - x_min
                h = y_max - y_min
                aspect = w / h if h > 0 else 0
                
                # Filtros espaciales: ruido o líneas
                if aspect > 8.0:
                    # Nombres largos a lo largo de toda la fila (ej. Test 6) o ruido esparcido a lo largo de la celda.
                    # Un nombre manuscrito largo tiene mucha tinta (area > 3500 o trazo muy grande).
                    # Si tiene poca tinta y su bounding box abarca toda la celda, es solo ruido esparcido.
                    if max_contour_area < 1200 and total_area_real < 3500:
                        continue
                    if aspect > 25.0:  # Línea horizontal pura residual
                        continue
                else:
                    # Firmas normales, compactas (aspect < 8.0).
                    fill_ratio = total_area_real / (w * h) if (w * h) > 0 else 0
                    if w < 30 or h < 15 or total_area_real < 400 or max_contour_area < 250 or fill_ratio < 0.03:
                        continue
                    
                # Filtro para "Autorizacion Uso de Datos Personales" y encabezados impresos:
                # El texto impreso suele ser muy largo y chato, Y está en la parte inferior (último 20%)
                if w > row_w * 0.75 and aspect > 5.5 and y1 > firma_col.shape[0] * 0.80:
                    continue
                    
                # Offset a coordenadas de la columna completa
                abs_x1, abs_y1 = x_min, y1 + y_min
                abs_x2, abs_y2 = x_max, y1 + y_max
                
                # Detectar si la tinta REAL (sin dilatar) toca los bordes de la fila
                # Esto indica que la firma cruza la línea de la tabla
                ink_touches_top = np.any(ink[:4, :] > 0)
                ink_touches_bottom = np.any(ink[-4:, :] > 0)
                
                # Guardar el bounding box final (formato polígono para dibujar)
                poly_box = np.array([
                    [abs_x1, abs_y1],
                    [abs_x2, abs_y1],
                    [abs_x2, abs_y2],
                    [abs_x1, abs_y2]
                ], dtype=np.int32)
                
                final_signature_boxes.append((poly_box, ink_touches_top, ink_touches_bottom))

            # Fusionar firmas cortadas por líneas de tabla
            # Solo fusiona si la tinta REAL toca ambos bordes Y al menos una
            # de las dos cajas es un fragmento (altura < 70% de la altura mediana)
            if len(final_signature_boxes) > 1:
                box_heights = [int(p[2][1]) - int(p[0][1]) for p, _, _ in final_signature_boxes]
                median_box_h = np.median(box_heights) if box_heights else 50
                
                merged = [final_signature_boxes[0]]
                for item in final_signature_boxes[1:]:
                    poly, touches_top, touches_bottom = item
                    prev_poly, prev_touches_top, prev_touches_bottom = merged[-1]
                    
                    prev_h = int(prev_poly[2][1]) - int(prev_poly[0][1])
                    curr_h = int(poly[2][1]) - int(poly[0][1])
                    
                    # Fusionar si:
                    # 1. La tinta toca ambos bordes (firma cruza la línea)
                    # 2. AMBAS cajas son fragmentos pequeños (< 85% de la mediana)
                    # 3. Las cajas están casi pegadas (gap < 5px)
                    gap = int(poly[0][1]) - int(prev_poly[2][1])
                    both_fragments = prev_h < median_box_h * 0.85 and curr_h < median_box_h * 0.85
                    is_split = prev_touches_bottom and touches_top and both_fragments and gap < 5
                    
                    if is_split:
                        new_x1 = min(int(prev_poly[0][0]), int(poly[0][0]))
                        new_y1 = min(int(prev_poly[0][1]), int(poly[0][1]))
                        new_x2 = max(int(prev_poly[2][0]), int(poly[2][0]))
                        new_y2 = max(int(prev_poly[2][1]), int(poly[2][1]))
                        merged_poly = np.array([
                            [new_x1, new_y1],
                            [new_x2, new_y1],
                            [new_x2, new_y2],
                            [new_x1, new_y2]
                        ], dtype=np.int32)
                        merged[-1] = (merged_poly, prev_touches_top, touches_bottom)
                    else:
                        merged.append(item)
                final_signature_boxes = merged

            # Dibujar los recuadros finales y guardar recortes
            out_img = firma_col.copy()
            crops_dir = os.path.join("output", "crops", os.path.splitext(base_name)[0])
            if os.path.exists(crops_dir):
                import shutil
                shutil.rmtree(crops_dir)
            os.makedirs(crops_dir, exist_ok=True)
            
            for i, (poly, _, _) in enumerate(final_signature_boxes):
                cv2.polylines(out_img, [poly], isClosed=True, color=(0, 0, 255), thickness=2)
                
                # Coordenadas para el recorte
                x1, y1 = poly[0]
                x2, y2 = poly[2]
                
                # Añadir un pequeño margen de 10px
                margin = 10
                cx1 = max(0, x1 - margin)
                cy1 = max(0, y1 - margin)
                cx2 = min(firma_col.shape[1], x2 + margin)
                cy2 = min(firma_col.shape[0], y2 + margin)
                
                crop = firma_col[cy1:cy2, cx1:cx2].copy()
                
                # Guardar recorte directo de la imagen original (sin procesamiento)
                if crop.size > 0:
                    crop_filename = os.path.join(crops_dir, f"firma_{i+1:02d}.jpg")
                    cv2.imwrite(crop_filename, crop)
                
            cv2.imwrite(os.path.join(paddle_out, base_name), out_img)
            print(f"  ✓ Encontradas {len(final_signature_boxes)} firmas")

    except Exception as e:
        print(f"\n⚠ Error al procesar: {e}")
        import traceback
        traceback.print_exc()