module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
      role_policies = {
        aws_load_balancer = data.aws_iam_policy.AmazonEBSCSIDriverPolicy.arn
      }
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
  enable_aws_gateway_api_controller = true

  enable_karpenter                           = true
  karpenter_enable_instance_profile_creation = true
  karpenter = {
    repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    repository_password = data.aws_ecrpublic_authorization_token.token.password
  }
  aws_gateway_api_controller = {
    repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    repository_password = data.aws_ecrpublic_authorization_token.token.password
    set = [{
      name  = "clusterVpcId"
      value = module.vpc.vpc_id
    }]
  }
  enable_cluster_autoscaler           = true
  enable_argocd                       = true
  enable_argo_rollouts                = true
  enable_argo_events                  = true
  enable_argo_workflows               = true
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
      { domain           = aws_acm_certificate.argocd_cert.domain_name,
        cert             = aws_acm_certificate.argocd_cert.arn,
        subnets          = join(",", module.vpc.public_subnets),
        cognito_endpoint = aws_cognito_user_pool.auth.endpoint,
        client_id        = aws_cognito_user_pool_client.auth.id,
        client_secret    = aws_cognito_user_pool_client.auth.client_secret,
    })]

  }

}


