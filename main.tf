terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.8"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "> 1.16.0"

    }
  }
  required_version = ">= 1.3.0"
}


data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.us-east-1
}


data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
