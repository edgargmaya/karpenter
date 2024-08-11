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
    bucket = "terraform-state-edgar-test-2"
    key    = "autoscaler_terraform.tfstate"
    region = "us-east-1"
  }
}

# Terraform Provider Block
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      "company" = "Edgar CO."
      "team"    = "Engineering"
    }
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "terraform-state-edgar-test-2"
    key    = "cluster_terraform.tfstate"
    region = var.aws_region
  }
}
