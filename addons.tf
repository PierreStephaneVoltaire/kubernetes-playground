
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

    coredns = {
      most_recent = true

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }



    kube-proxy = {
    }
    eks-pod-identity-agent = {
      resolve_conflicts = "OVERWRITE"
      before_compute = true
      most_recent    = true
    }

  }

  # enable_karpenter                           = true
  # karpenter_enable_instance_profile_creation = true
  # karpenter = {
  #   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  #   repository_password = data.aws_ecrpublic_authorization_token.token.password
  # }
  helm_releases = {
    prometheus-adapter = {
      description      = "A Helm chart for k8s prometheus adapter"
      namespace        = "prometheus-adapter"
      create_namespace = true
      chart            = "prometheus-adapter"
      chart_version    = "4.2.0"
      repository       = "https://prometheus-community.github.io/helm-charts"
      values = [
        <<-EOT
          replicas: 2
          podDisruptionBudget:
            enabled: true
        EOT
      ]
    }
  }
  enable_kube_prometheus_stack                 = true
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }
  enable_metrics_server = true
  enable_cluster_autoscaler = true
  enable_aws_cloudwatch_metrics                = true
  enable_aws_efs_csi_driver                    = true
  enable_aws_privateca_issuer                  = true
  enable_secrets_store_csi_driver              = true
  enable_secrets_store_csi_driver_provider_aws = true
  enable_external_dns = true
  enable_external_secrets = true
depends_on = [kubectl_manifest.eni_configs]

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
output "caData" {
  value = module.eks.cluster_certificate_authority_data
}
resource "kubectl_manifest" "eni_configs" {
  count = length(data.terraform_remote_state.network.outputs.private_subnets)

  yaml_body = <<-YAML
  apiVersion: crd.k8s.amazonaws.com/v1alpha1
  kind: ENIConfig
  metadata:
    name: ${element(data.terraform_remote_state.network.outputs.azs, count.index)}
  spec:
    securityGroups:
      - ${module.eks.cluster_primary_security_group_id}
    subnet: ${element(data.terraform_remote_state.network.outputs.private_subnets, count.index)}
  YAML
}
