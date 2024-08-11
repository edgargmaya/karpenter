FROM openjdk:17-slim

WORKDIR /app

COPY target/kafka-consumer-1.0-SNAPSHOT.jar /app/kafka-consumer.jar

ENTRYPOINT ["java", "-jar", "/app/kafka-consumer.jar"]
