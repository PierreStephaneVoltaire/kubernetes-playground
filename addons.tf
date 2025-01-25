
data "aws_route53_zone" "main" {
  name = var.domain_name
}
module "eks_blueprints_addons" {
  source            = "aws-ia/eks-blueprints-addons/aws"
  version           = "~> 1.0"
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn
  eks_addons = {
    aws-ebs-csi-driver = {
      resolve_conflicts        = "OVERWRITE"
      most_recent              = true
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn

    }

    coredns = {
      most_recent = true

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    eks-pod-identity-agent = {
      before_compute = true
      most_recent    = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_SUBNET_DISCOVERY = "true"
        }
    }) }

    kube-proxy = {
    }
    eks-pod-identity-agent = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }

  }


  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }
  enable_metrics_server = true
  enable_external_dns   = true
}

resource "kubernetes_storage_class" "gp3" {
  depends_on             = [module.eks_blueprints_addons.eks_addons]
  volume_binding_mode    = "WaitForFirstConsumer"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  parameters = {
    type       = "gp3"
    throughput = 125
    encrypted  = true
    fsType     = "ext4"
  }
  storage_provisioner = "ebs.csi.aws.com"
}

