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

# ── Etapa 2: Imagen Final (Runtime) ──
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

COPY --from=java-builder /app/MicroservicioPlanilla/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-Xmx512m", "-Xms256m", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=50.0", "-jar", "app.jar"]
