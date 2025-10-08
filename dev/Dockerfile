# syntax=docker/dockerfile:1.4
FROM maven:3.8.2-eclipse-temurin-17 AS build

# Build arguments
ARG ND4J_CLASSIFIER
ARG APP_VERSION=latest
ARG BUILD_DATE
ARG VCS_REF

# Labels for metadata (following Label Schema convention)
LABEL org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.name="CompreFace" \
      org.label-schema.description="Free and open-source face recognition system" \
      org.label-schema.version=${APP_VERSION} \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url="https://github.com/jamestrichardson/CompreFace" \
      org.label-schema.schema-version="1.0" \
      maintainer="jamestrichardson"

WORKDIR /workspace/compreface

# Cache Maven dependencies
COPY pom.xml .
COPY api/pom.xml api/
COPY admin/pom.xml admin/
COPY common/pom.xml common/
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B dependency:go-offline

# Copy source code
COPY api api
COPY admin admin
COPY common common

# Build application
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package \
    -DskipTests \
    -Dcheckstyle.skip \
    -Dasciidoctor.skip \
    -Djacoco.skip \
    -Dmaven.gitcommitid.skip \
    -Dspring-boot.repackage.skip \
    -Dnd4j.classifier=$ND4J_CLASSIFIER

# Core service image
FROM eclipse-temurin:17-jre-focal AS frs_core

# Create a non-root user
RUN useradd -r -u 1001 -g root appuser

WORKDIR /app

# Copy jar from build stage
COPY --from=build --chown=appuser:root /workspace/compreface/api/target/*.jar ./app.jar

# Configure environment
ENV API_JAVA_OPTS="-Xms512m -Xmx2g -XX:+UseG1GC"

# Switch to non-root user
USER 1001

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Set entrypoint
ENTRYPOINT ["sh", "-c", "java ${API_JAVA_OPTS} -jar /app/app.jar"]

# Admin service image
FROM eclipse-temurin:17-jre-focal AS frs_crud

# Create a non-root user
RUN useradd -r -u 1001 -g root appuser

WORKDIR /app

# Copy jar from build stage
COPY --from=build --chown=appuser:root /workspace/compreface/admin/target/*.jar ./app.jar

# Configure environment
ARG APPERY_API_KEY
ENV APPERY_API_KEY=${APPERY_API_KEY} \
    ADMIN_JAVA_OPTS="-Xms256m -Xmx1g -XX:+UseG1GC"

# Switch to non-root user
USER 1001

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8081/actuator/health || exit 1

# Set entrypoint
ENTRYPOINT ["sh", "-c", "java ${ADMIN_JAVA_OPTS} -jar /app/app.jar"]
