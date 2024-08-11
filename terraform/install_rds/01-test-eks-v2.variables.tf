# EKS Cluster Input Variables
variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type = string
  default = "us-east-1"  
}

variable "subnet_1" {
  description = "Random subnet in us-east-1"
  type        = string
}

variable "subnet_2" {
  description = "Random subnet in us-east-1"
  type        = string
}

variable "user" {
  description = "Bucket created by ./init.sh"
  type        = string
}

variable "pass" {
  description = "Bucket created by ./init.sh"
  type        = string
}

variable "default_vpc" {
  description = "Default VPC in us-east-1"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Default db subnet group name"
  type        = string
}
