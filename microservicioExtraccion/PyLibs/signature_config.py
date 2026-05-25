from os import environ

import pytesseract


def configure_runtime() -> None:
    pass


def configure_tesseract(
    tesseract_cmd: str = r"C:\Program Files\Tesseract-OCR\tesseract.exe",
) -> None:
    pytesseract.pytesseract.tesseract_cmd = environ.get(
        "TESSERACT_CMD", tesseract_cmd
    )
