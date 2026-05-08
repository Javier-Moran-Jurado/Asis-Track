# Etapa 1: Construcción de dependencias Python (Builder)
FROM eclipse-temurin:17-jdk-jammy AS python-builder

WORKDIR /build

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        python-is-python3 \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# Crear y usar un entorno virtual para facilitar la copia de dependencias
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt /build/requirements.txt

# Instalar dependencias Python en el entorno virtual
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir paddlepaddle==3.2.0 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/ \
    && pip install --no-cache-dir "paddleocr[all]" \
    && pip install --no-cache-dir pytesseract \
    && pip install --no-cache-dir tesseract \
    && pip install --no-cache-dir -r /build/requirements.txt


# Etapa 2: Imagen Final (Runtime)
FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

# Instalar dependencias del sistema mínimas requeridas para tiempo de ejecución
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python-is-python3 \
        libgl1 \
        libglib2.0-0 \
        tesseract-ocr \
        tesseract-ocr-spa \
    && rm -rf /var/lib/apt/lists/*

# Copiar el entorno virtual Python desde la etapa de construcción
COPY --from=python-builder /opt/venv /opt/venv

# Habilitar el entorno virtual por defecto para que Java pueda llamar a los scripts
ENV PATH="/opt/venv/bin:$PATH"
ENV TESSERACT_CMD=/usr/bin/tesseract

# Copiar la librería de Python y el JAR ya compilado
COPY PyLibs /app/PyLibs
COPY target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java","-jar","app.jar"]
