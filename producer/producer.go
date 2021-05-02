package producer

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

// DatabaseEvent represents the struct of the value in a Kafka message
type DatabaseEvent struct {
	TableName string
	JsonData  []byte
	Statement string
}

func ProduceEvent(dbEvent DatabaseEvent) {
	p, err := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers": os.Getenv("kafka_server"),
		"sasl.username":     os.Getenv("kafka_username"),
		"sasl.password":     os.Getenv("kafka_password")})
	if err != nil {
		panic(err)
	}

	defer p.Close()

	// Delivery report handler for produced messages
	go func() {
		for e := range p.Events() {
			switch ev := e.(type) {
			case *kafka.Message:
				if ev.TopicPartition.Error != nil {
					fmt.Printf("Delivery failed: %v\n", ev.TopicPartition)
				} else {
					fmt.Printf("Delivered message to %v\n", ev.TopicPartition)
				}
			}
		}
	}()
	topic := "dumbo"
	recordKey := "db"
	recordValue, _ := json.Marshal(&dbEvent)
	// Produce messages to topic (asynchronously)
	p.Produce(&kafka.Message{
		TopicPartition: kafka.TopicPartition{Topic: &topic, Partition: kafka.PartitionAny},
		Value:          recordValue,
		Key:            []byte(recordKey),
	}, nil)

	// Wait for message deliveries before shutting down
	p.Flush(15 * 1000)
}
