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
locals {
  l = length(data.terraform_remote_state.network.outputs.private_subnets)
  primary = slice(data.terraform_remote_state.network.outputs.private_subnets, 0, (local.l/2))
  secondary = slice(data.terraform_remote_state.network.outputs.private_subnets, (local.l/2), local.l)
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
module "cost_management" {
  source   = "./cost"
  app_name = var.app_name
  contact  = var.contact
  tags     = var.tags
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.bucket
    key    = var.network_key
    region = data.aws_region.current.name
  }
}
