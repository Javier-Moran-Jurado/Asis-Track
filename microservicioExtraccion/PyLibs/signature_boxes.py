import cv2
import numpy as np


def extract_signature_boxes(
    firma_col: np.ndarray, enhanced: np.ndarray, row_bounds: list[tuple[int, int]]
) -> list[tuple[np.ndarray, bool, bool]]:
    final_signature_boxes = []

    for y1, y2 in row_bounds:
        row_h = y2 - y1
        row_w = firma_col.shape[1]

        row_img = enhanced[y1:y2, 0:row_w]
        gray_row = cv2.cvtColor(row_img, cv2.COLOR_BGR2GRAY)

        binary = cv2.adaptiveThreshold(
            gray_row, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 21, 10
        )

        h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (40, 1))
        h_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, h_kernel)
        ink = cv2.subtract(binary, h_lines)

        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        dilated = cv2.dilate(ink, kernel, iterations=2)

        contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if not contours:
            continue

        ink_pixels = cv2.countNonZero(ink)
        if ink_pixels < 100:
            continue

        x_min, y_min = row_w, row_h
        x_max, y_max = 0, 0

        significant_contours = 0
        total_area_real = 0
        max_contour_area = 0

        for cnt in contours:
            area_real = cv2.contourArea(cnt)
            x, y, w, h = cv2.boundingRect(cnt)

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

        if aspect > 8.0:
            if max_contour_area < 1200 and total_area_real < 3500:
                continue
            if aspect > 25.0:
                continue
        else:
            fill_ratio = total_area_real / (w * h) if (w * h) > 0 else 0
            if (
                w < 30
                or h < 15
                or total_area_real < 400
                or max_contour_area < 250
                or fill_ratio < 0.03
            ):
                continue

        if w > row_w * 0.75 and aspect > 5.5 and y1 > firma_col.shape[0] * 0.80:
            continue

        abs_x1, abs_y1 = x_min, y1 + y_min
        abs_x2, abs_y2 = x_max, y1 + y_max

        ink_touches_top = np.any(ink[:4, :] > 0)
        ink_touches_bottom = np.any(ink[-4:, :] > 0)

        poly_box = np.array(
            [[abs_x1, abs_y1], [abs_x2, abs_y1], [abs_x2, abs_y2], [abs_x1, abs_y2]],
            dtype=np.int32,
        )

        final_signature_boxes.append((poly_box, ink_touches_top, ink_touches_bottom))

    return final_signature_boxes


def merge_split_signatures(
    boxes: list[tuple[np.ndarray, bool, bool]]
) -> list[tuple[np.ndarray, bool, bool]]:
    if len(boxes) <= 1:
        return boxes

    box_heights = [int(p[2][1]) - int(p[0][1]) for p, _, _ in boxes]
    median_box_h = np.median(box_heights) if box_heights else 50

    merged = [boxes[0]]
    for item in boxes[1:]:
        poly, touches_top, touches_bottom = item
        prev_poly, prev_touches_top, prev_touches_bottom = merged[-1]

        prev_h = int(prev_poly[2][1]) - int(prev_poly[0][1])
        curr_h = int(poly[2][1]) - int(poly[0][1])

        gap = int(poly[0][1]) - int(prev_poly[2][1])
        both_fragments = prev_h < median_box_h * 0.85 and curr_h < median_box_h * 0.85
        is_split = prev_touches_bottom and touches_top and both_fragments and gap < 5

        if is_split:
            new_x1 = min(int(prev_poly[0][0]), int(poly[0][0]))
            new_y1 = min(int(prev_poly[0][1]), int(poly[0][1]))
            new_x2 = max(int(prev_poly[2][0]), int(poly[2][0]))
            new_y2 = max(int(prev_poly[2][1]), int(poly[2][1]))
            merged_poly = np.array(
                [[new_x1, new_y1], [new_x2, new_y1], [new_x2, new_y2], [new_x1, new_y2]],
                dtype=np.int32,
            )
            merged[-1] = (merged_poly, prev_touches_top, touches_bottom)
        else:
            merged.append(item)

    return merged
