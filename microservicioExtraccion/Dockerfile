FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema necesarias para OpenCV y Tesseract
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
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY PyLibs/ ./PyLibs/
COPY main.py .

ENV TESSERACT_CMD=/usr/bin/tesseract
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
