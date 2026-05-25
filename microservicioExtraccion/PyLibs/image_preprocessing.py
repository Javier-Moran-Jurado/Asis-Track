import cv2
import numpy as np

_CLAHE_OCR = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(16, 16))
_CLAHE_ENH = cv2.createCLAHE(clipLimit=4.0, tileGridSize=(8, 8))


def preprocess_for_ocr(img: np.ndarray, target_width: int = 1800) -> np.ndarray:
    h, w = img.shape[:2]
    if w != target_width:
        scale = target_width / w
        img = cv2.resize(img, None, fx=scale, fy=scale, interpolation=cv2.INTER_LINEAR)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray = _CLAHE_OCR.apply(gray)
    gray = cv2.GaussianBlur(gray, (5, 5), 0)
    binary = cv2.adaptiveThreshold(
        gray,
        255,
        cv2.ADAPTIVE_THRESH_MEAN_C,
        cv2.THRESH_BINARY,
        blockSize=31,
        C=18,
    )
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2, 2))
    binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, k)
    binary = cv2.dilate(binary, k, iterations=1)
    return cv2.cvtColor(binary, cv2.COLOR_GRAY2BGR)


def enhance_for_detection(img_bgr: np.ndarray) -> np.ndarray:
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    enhanced = _CLAHE_ENH.apply(gray)
    enhanced = cv2.GaussianBlur(enhanced, (3, 3), 0)
    return enhanced
