terraform {
  required_version = ">= 1.6.0"

  backend "remote" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "arcadia-lab"
      ManagedBy   = "terraform"
      Environment = "lab"
    }
  }
}
