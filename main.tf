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

    vault = {
      source  = "hashicorp/vault"
      version = "4.6.0"

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
  source                = "./security"
  allowed_ips           = var.allowed_ips
  app_name              = var.app_name
  argo_domain           = "https://${local.argo_domain}"
  users                 = var.users
  domain_name           = var.domain_name
  tags                  = var.tags
  vault_version         = var.vault_version
  alb_cert_arn          = module.network.wildcard_cert
  public_subnets_string = join(",", module.vpc.public_subnets)
  eks_issuer            = module.eks.oidc_provider
  oidc_provider         = module.eks.oidc_provider_arn
  jenkins_domain        = "jenkins.${var.domain_name}"
}
module "jenkins" {
  source = "./deployments"


  client_id         = module.security.jenkins_app_client_id
  client_secret     = module.security.jenkins__app_client_secret
  cognito_uri       = module.security.cognito_endpoint
  oidc_provider_arn = module.eks.oidc_provider_arn
}


module "network" {
  source      = "./networking"
  domain_name = var.domain_name
}