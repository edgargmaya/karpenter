FROM openjdk:17-slim

WORKDIR /app

COPY target/kafka-producer-1.0-SNAPSHOT.jar /app/kafka-producer.jar

ENTRYPOINT ["java", "-jar", "/app/kafka-producer.jar"]
