# ── Etapa 1: Compilación Java desde raíz del repo ──
# Build context debe ser la raíz del monorepo para acceder a ../Encryption
FROM maven:3.9-eclipse-temurin-17 AS java-builder
WORKDIR /app

COPY Encryption ./Encryption
COPY MicroservicioPlanilla ./MicroservicioPlanilla

WORKDIR /app/Encryption
RUN mvn install -DskipTests -B

WORKDIR /app/MicroservicioPlanilla
RUN mvn dependency:go-offline -B
RUN mvn package -DskipTests -B

# ── Etapa 2: Construcción de dependencias Python ──
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
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY MicroservicioPlanilla/requirements.txt /build/requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir paddlepaddle==3.2.0 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/ \
    && pip install --no-cache-dir "paddleocr[all]" \
    && pip install --no-cache-dir pytesseract \
    && pip install --no-cache-dir --upgrade setuptools wheel \
    && pip install --no-cache-dir opencv-python-headless \
    && pip install --no-cache-dir -r /build/requirements.txt

# ── Etapa 3: Imagen Final (Runtime) ──
FROM eclipse-temurin:17-jre
WORKDIR /app
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python-is-python3 \
        libgl1 \
        libglib2.0-0 \
        tesseract-ocr \
        tesseract-ocr-spa \
    && rm -rf /var/lib/apt/lists/*
COPY --from=python-builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV TESSERACT_CMD=/usr/bin/tesseract
COPY MicroservicioPlanilla/PyLibs /app/PyLibs
COPY --from=java-builder /app/MicroservicioPlanilla/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-Xmx512m", "-Xms256m", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=50.0", "-jar", "app.jar"]
