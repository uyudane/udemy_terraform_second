# ------------------------------
# Terraform configuration
# ------------------------------
terraform {
  required_version = ">=0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
    }
  }
  backend "s3" {
    bucket  = "tastylog-tfstate-bucket-yudai"
    key     = "tastylog-dev.tfstate"
    region  = "ap-northeast-1"
    profile = "yudai"
  }
}

# ------------------------------
# Provider
# ------------------------------
provider "aws" {
  profile = "yudai"
  region  = "ap-northeast-1"
}

provider "aws" {
  alias   = "virginia"
  profile = "yudai"
  region  = "us-east-1"
}

# ------------------------------
# Varialbles
# ------------------------------
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain" {
  type = string
}
