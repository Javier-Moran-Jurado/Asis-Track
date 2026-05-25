import os
import shutil
from pathlib import Path

import cv2
import numpy as np


def save_debug(img_bgr: np.ndarray, firma: dict, bounds: dict, path: str) -> None:
    dbg = img_bgr.copy()
    cv2.rectangle(
        dbg,
        (firma["x"], firma["y"]),
        (firma["x"] + firma["w"], firma["y"] + firma["h"]),
        (0, 255, 0),
        2,
    )
    cv2.rectangle(
        dbg,
        (bounds["x1"], bounds["y1"]),
        (bounds["x2"], bounds["y2"]),
        (0, 0, 255),
        2,
    )
    cv2.imwrite(path, dbg)


def save_signature_crops(
    base_name: str,
    firma_col: np.ndarray,
    final_signature_boxes: list[tuple[np.ndarray, bool, bool]],
    output_dir: str | os.PathLike[str] = "output",
    margin: int = 10,
) -> tuple[np.ndarray, list[str]]:
    out_img = firma_col.copy()
    crops_dir = Path(output_dir) / "crops" / Path(base_name).stem
    if os.path.exists(crops_dir):
        shutil.rmtree(crops_dir)
    os.makedirs(crops_dir, exist_ok=True)

    crop_paths: list[str] = []

    for i, (poly, _, _) in enumerate(final_signature_boxes):
        cv2.polylines(out_img, [poly], isClosed=True, color=(0, 0, 255), thickness=2)

        x1, y1 = poly[0]
        x2, y2 = poly[2]

        cx1 = max(0, x1 - margin)
        cy1 = max(0, y1 - margin)
        cx2 = min(firma_col.shape[1], x2 + margin)
        cy2 = min(firma_col.shape[0], y2 + margin)

        crop = firma_col[cy1:cy2, cx1:cx2].copy()
        if crop.size > 0:
            crop_filename = os.path.join(crops_dir, f"firma_{i + 1:02d}.jpg")
            cv2.imwrite(crop_filename, crop)
            crop_paths.append(os.path.abspath(crop_filename))

    return out_img, crop_paths
