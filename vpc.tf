module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name                   = "${var.app_name}-vpc"
  cidr                   = var.vpc_cdr
  azs                    = var.vpc_azs
  private_subnets        = var.vpc_private_subnet_cidr
  public_subnets         = var.vpc_public_subnet_cidr
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}
