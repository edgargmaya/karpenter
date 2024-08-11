# Terraform Settings Block
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 2.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
    }
  }

  backend "s3" {
    bucket = "terraform-state-wildfork-demo-coupon-v1"
    key    = "rds_terraform.tfstate"
    region = "us-east-1"
  }
}

# Terraform Provider Block
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      "company" = "WildFork"
      "team"    = "Engineering"
    }
  }
}
