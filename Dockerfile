FROM eclipse-temurin:21-jre

WORKDIR /app
COPY porto-api.jar /app/porto-api.jar

ENV PORTO_API_HOME=/runtime
ENV API_ENV=dev
ENV LOG_PATH=/runtime/logs

EXPOSE 9091 9092

ENTRYPOINT ["java", "-jar", "/app/porto-api.jar"]
