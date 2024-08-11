# Terraform Settings Block
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_mq_broker" "rabbitmq" {
  broker_name       = "my-rabbitmq"
  deployment_mode   = "SINGLE_INSTANCE"
  engine_type       = "RABBITMQ"
  engine_version    = "3.9.27"
  host_instance_type = "mq.t3.micro"
  publicly_accessible = true

  user {
    username = "admin"
    password = "StrongPassword123!"
  }

  configuration {
    id = aws_mq_configuration.rabbitmq.id
    revision = aws_mq_configuration.rabbitmq.latest_revision
  }
}

resource "aws_mq_configuration" "rabbitmq" {
  name = "my-rabbitmq-configuration"
  description = "RabbitMQ Configuration"
  engine_type = "RABBITMQ"
  engine_version  = "3.9.27"

  data = <<DATA
# Default RabbitMQ delivery acknowledgement timeout is 30 minutes in milliseconds
consumer_timeout = 1800000
DATA
}

resource "aws_security_group" "mq_sg" {
  name        = "mq_sg"
  description = "Allow RabbitMQ traffic"
  vpc_id      = "vpc-3cd0b45a"

  ingress {
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
