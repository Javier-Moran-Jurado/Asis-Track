import logging
import re

import numpy as np

logger = logging.getLogger(__name__)


class PaddleColumnDetector:
    """Detector de columna 'Firma' usando PaddleOCR (español)."""

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def _init_ocr(self):
        if self._initialized:
            return
        try:
            from paddleocr import PaddleOCR
            logger.info("[PaddleColumnDetector] Inicializando PaddleOCR (lang='es')...")
            self._ocr = PaddleOCR(
                use_angle_cls=True,
                lang='es',
                show_log=False,
                use_gpu=False,
            )
            self._initialized = True
            logger.info("[PaddleColumnDetector] PaddleOCR listo")
        except Exception as e:
            logger.exception("[PaddleColumnDetector] Error inicializando PaddleOCR")
            raise

    def find_firma(self, img_bgr) -> dict | None:
        """Busca la palabra 'Firma' en la imagen y devuelve bounding box."""
        self._init_ocr()

        result = self._ocr.ocr(img_bgr, cls=True)
        if result is None or result[0] is None:
            logger.info("[PaddleColumnDetector] PaddleOCR no detectó texto")
            return None

        detected_texts = []
        for line in result[0]:
            box, (text, conf) = line
            detected_texts.append(f"'{text}'({conf:.2f})")
            text_lower = text.lower().strip()

            # Regex permisivo: firma, fima, ferma, firm, etc.
            if re.search(r"f[ií]?r?m?a?", text_lower) and len(text_lower) >= 3:
                x_coords = [p[0] for p in box]
                y_coords = [p[1] for p in box]
                match = {
                    "x": int(min(x_coords)),
                    "y": int(min(y_coords)),
                    "w": int(max(x_coords) - min(x_coords)),
                    "h": int(max(y_coords) - min(y_coords)),
                    "cx": int(np.mean(x_coords)),
                    "cy": int(np.mean(y_coords)),
                    "text": text,
                    "conf": float(conf),
                }
                logger.info(
                    f"[PaddleColumnDetector] Match: '{text}' conf={conf:.2f} "
                    f"pos=({match['x']},{match['y']}) size=({match['w']}x{match['h']})"
                )
                return match

        logger.info(
            f"[PaddleColumnDetector] Detectó {len(result[0])} líneas: {detected_texts[:10]}..."
        )
        logger.warning("[PaddleColumnDetector] No encontró 'Firma'")
        return None
