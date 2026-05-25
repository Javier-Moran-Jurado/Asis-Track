FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema necesarias para OpenCV, Tesseract y compilación de PyMuPDF
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    tesseract-ocr \
    tesseract-ocr-spa \
    swig \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir paddlepaddle==3.2.0 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/ \
    && pip install --no-cache-dir "paddleocr[all]" \
    && pip install --no-cache-dir -r requirements.txt

# Pre-descargar modelo de detección de PaddleOCR durante build
RUN python -c "from paddleocr import TextDetection; m = TextDetection(thresh=0.01, box_thresh=0.02, unclip_ratio=2.5, limit_side_len=2560); del m"

COPY PyLibs/ ./PyLibs/
COPY main.py .

ENV TESSERACT_CMD=/usr/bin/tesseract
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
