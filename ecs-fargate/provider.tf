terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = ">= 4.0.0, < 5.0"
  }
  #  backend "s3" {
  #    key = "0_tfmh.tfstate"
  #  }
}

provider "aws" {
  region = var.region
}
