# ── Etapa 1: Compilación desde raíz del repo ──
# Build context debe ser la raíz del monorepo para acceder a ../Encryption
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app

COPY Encryption ./Encryption
COPY MicroservicioUsuario ./MicroservicioUsuario

WORKDIR /app/Encryption
RUN mvn install -DskipTests -B

WORKDIR /app/MicroservicioUsuario
RUN mvn dependency:go-offline -B
RUN mvn package -DskipTests -B

# ── Etapa 2: Runtime ──
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/MicroservicioUsuario/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
