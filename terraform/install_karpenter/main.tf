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
    key    = "karpenter_terraform.tfstate"
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

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "terraform-state-edgar-test-2"
    key    = "cluster_terraform.tfstate"
    region = var.aws_region
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}