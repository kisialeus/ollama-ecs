provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket  = "ks-projects-terraform"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
