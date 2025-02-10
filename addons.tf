
data "aws_route53_zone" "main" {
  name = var.domain_name
}
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.us-east-1
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
    eks-pod-identity-agent = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }

  }
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [
      {
        name  = "enableServiceMutatorWebhook"
        value = "false"
      }
    ]
  }
  enable_metrics_server     = true
  enable_cluster_autoscaler = true
  enable_aws_cloudwatch_metrics                = true
  depends_on = [kubectl_manifest.eni_configs, module.eks]

}

resource "kubernetes_storage_class" "gp3" {
  depends_on = [module.eks_blueprints_addons.eks_addons]
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
output "caData" {
  value = module.eks.cluster_certificate_authority_data
}

resource "kubectl_manifest" "eni_configs" {
  count = length(local.secondary)

  yaml_body = <<-YAML
  apiVersion: crd.k8s.amazonaws.com/v1alpha1
  kind: ENIConfig
  metadata:
    name: ${element(data.terraform_remote_state.network.outputs.azs, count.index)}
  spec:
    securityGroups:
      - ${module.eks.cluster_primary_security_group_id}
    subnet: ${element(local.secondary, count.index)}
  YAML
}
