terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "smus-demo-terraform-state"
    key            = "smus-networking-demo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "smus-demo-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
