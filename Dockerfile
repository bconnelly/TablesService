# Build stage
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
# Download dependencies separately to leverage Docker layer cache
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests -B

# Runtime stage
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

RUN groupadd --system appgroup && \
    useradd --system --gid appgroup appuser

COPY --from=build /app/TablesService.war app.war

RUN chown appuser:appgroup app.war

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.war"]