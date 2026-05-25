from os import environ

import pytesseract


def configure_runtime() -> None:
    hf_token = environ.get("HF_TOKEN")
    if hf_token:
        environ["HF_TOKEN"] = hf_token
    environ["FLAGS_use_mkldnn"] = "0"
    environ["MKLDNN_VERBOSE"] = "0"
    environ["FLAGS_enable_pir_api"] = "0"


def configure_tesseract(
    tesseract_cmd: str = r"C:\Program Files\Tesseract-OCR\tesseract.exe",
) -> None:
    pytesseract.pytesseract.tesseract_cmd = environ.get(
        "TESSERACT_CMD", tesseract_cmd
    )
