# ── Stage 1: Build ───────────────────────────────────────────────
# Use a full JDK image to compile and package the code into a .jar
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app

# Copy Maven wrapper and pom.xml first so Docker caches dependencies
# (only re-downloads if pom.xml changes, not every code change)
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
RUN ./mvnw dependency:go-offline -q

# Now copy source code and build the jar
COPY src src
RUN ./mvnw package -DskipTests -q

# ── Stage 2: Run ─────────────────────────────────────────────────
# Use a smaller JRE-only image to run — no compiler needed at runtime
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copy only the built jar from stage 1 — keeps the final image small
COPY --from=builder /app/target/*.jar app.jar

# The service account key is mounted at runtime via Docker volume
# These environment variables are passed in via docker run or docker-compose
ENV FIREBASE_SERVICE_ACCOUNT_PATH=/secrets/firebase-service-account.json

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
