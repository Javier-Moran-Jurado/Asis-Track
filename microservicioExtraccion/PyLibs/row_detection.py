import cv2
import numpy as np


def detect_rows_in_column(firma_col: np.ndarray) -> list[tuple[int, int]]:
    img_h, img_w = firma_col.shape[:2]
    gray = cv2.cvtColor(firma_col, cv2.COLOR_BGR2GRAY)

    binary = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 21, 10
    )

    h_len = max(int(img_w * 0.4), 20)
    h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (h_len, 1))
    h_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, h_kernel)

    proj = np.sum(h_lines, axis=1)

    y_lines = []
    in_line = False
    start_y = 0
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
        y2 = y_lines[i + 1]
        h = y2 - y1
        if h > 20:
            rows.append((y1, y2))

    return rows


def refine_rows(row_bounds: list[tuple[int, int]]) -> list[tuple[int, int]]:
    if len(row_bounds) <= 2:
        return row_bounds

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

    return refined_rows
