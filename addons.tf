module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.AmazonEBSCSIDriverPolicy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

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
    vpc-cni = {
      most_recent = true
    }

    kube-proxy = {}
    eks-pod-identity-agent = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }

  }

  enable_cluster_autoscaler           = true
  enable_argocd                       = true
  enable_argo_rollouts                = true
  enable_argo_events                  = true
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }
  enable_metrics_server                        = true
  enable_external_dns                          = true
  enable_external_secrets                      = true
  enable_aws_privateca_issuer                  = true
  enable_aws_efs_csi_driver                    = true
  enable_secrets_store_csi_driver              = true
  enable_secrets_store_csi_driver_provider_aws = true
  enable_kube_prometheus_stack                 = true
  enable_cert_manager                          = true
  cert_manager = {
    wait = true
  }

  cert_manager_route53_hosted_zone_arns = [data.aws_route53_zone.main.arn]

  argocd = {
    create_namespace = true
    values = [templatefile("${path.module}/argo.yaml",
      { domain           = local.argo_domain,
        cert             = module.network.wildcard_cert,
        subnets          = join(",", module.vpc.public_subnets),
        cognito_endpoint = module.security.cognito_endpoint
        client_id        = module.security.argo_app_client_id
        client_secret    = module.security.argo_app_client_secret
    })]

  }

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

