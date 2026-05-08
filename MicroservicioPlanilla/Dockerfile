FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python-is-python3 \
        libgl1 \
        libglib2.0-0 \
        tesseract-ocr \
        tesseract-ocr-spa \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
COPY PyLibs /app/PyLibs

# Dependencias Python para extracción OCR/firma
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir paddlepaddle==3.2.0 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/ \
    && pip install --no-cache-dir "paddleocr[all]" \
    && pip install --no-cache-dir pytesseract \
    && pip install --no-cache-dir tesseract \
    && pip install --no-cache-dir -r /app/requirements.txt

ENV TESSERACT_CMD=/usr/bin/tesseract

COPY target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java","-jar","app.jar"]