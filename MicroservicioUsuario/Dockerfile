FROM eclipse-temurin:17-jdk-alpine
LABEL authors="andres"
WORKDIR /app
COPY target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]