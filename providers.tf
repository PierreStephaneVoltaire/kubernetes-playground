provider "aws" {
  region = "ca-central-1"
  default_tags {
    tags = var.tags
  }
}
data "aws_eks_cluster_auth" "eks_auth" {
  name = module.eks.cluster_name
}
provider "kubernetes" {
  host  = module.eks.cluster_endpoint
  token = data.aws_eks_cluster_auth.eks_auth.token

  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

provider "helm" {
  kubernetes {
    host  = module.eks.cluster_endpoint
    token = data.aws_eks_cluster_auth.eks_auth.token

    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  }
}

provider "kubectl" {
  host  = module.eks.cluster_endpoint
  token = data.aws_eks_cluster_auth.eks_auth.token

  load_config_file       = false
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

