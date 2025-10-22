terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.53.0"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.access_key #used for local run
  secret_key = var.secret_key #used for local run
  default_tags {
    tags = {
      Source = "https://github.com/kunduso/aws-beanstalk-nodejs-terraform"
    }
  }
}