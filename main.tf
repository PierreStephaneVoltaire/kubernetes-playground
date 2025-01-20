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
module "cost_management" {
  source   = "./cost"
  app_name = var.app_name
  contact  = var.contact
  tags     = var.tags
}
module "security" {
  source      = "./security"
  allowed_ips = var.allowed_ips
  app_name    = var.app_name
  argo_domain = "https://${local.argo_domain}"
  argo_users  = var.argo_users
  domain_name = var.domain_name
  tags        = var.tags
}