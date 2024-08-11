package com.test.kafka;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.util.Properties;

public class Producer {
    public static void main(String[] args) {
        String topicName = "topic";
        Properties props = new Properties();
        props.put("bootstrap.servers", "test-kafka-bootstrap:9092");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

        KafkaProducer<String, String> producer = new KafkaProducer<>(props);

        for (int i = 0; i < 999000; i++) {
            producer.send(new ProducerRecord<>(topicName, Integer.toString(i), "Message " + i));
            System.out.println("Message " + i + " sent");
            try {
                Thread.sleep(15);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                System.err.println("Interrupted while processing");
            }
        }
        producer.close();
    }
}
