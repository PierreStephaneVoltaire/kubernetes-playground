module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "~> 20.33.1"
  cluster_name                             = "${var.app_name}-cluster"
  cluster_version                          = var.cluster_version
  cluster_enabled_log_types                = []
  cluster_endpoint_public_access_cidrs     = var.allowed_ips
  node_iam_role_additional_policies        = { AmazonEBSCSIDriverPolicy = data.aws_iam_policy.AmazonEBSCSIDriverPolicy.arn, AmazonEKSLoadBalancingPolicy = data.aws_iam_policy.AmazonEKSLoadBalancingPolicy.arn, AmazonEKSCNIPolicy = data.aws_iam_policy.AmazonEKSCNIPolicy.arn, AmazonEKSWorkerNodePolicy = data.aws_iam_policy.AmazonEKSWorkerNodePolicy.arn, AmazonSSMManagedInstanceCore = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn, }
  iam_role_additional_policies             = { AmazonEKSServiceRolePolicy = data.aws_iam_policy.AmazonEKSClusterPolicy.arn, AmazonEKSServicePolicy = data.aws_iam_policy.AmazonEKSServicePolicy.arn, AmazonEKSVPCResourceController = data.aws_iam_policy.AmazonEKSVPCResourceController.arn }
  cluster_endpoint_public_access           = true
  enable_irsa                              = true
  cluster_service_ipv4_cidr                = var.cluster_service_ipv4_cidr
  enable_cluster_creator_admin_permissions = true
  vpc_id                                   = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids                               = data.terraform_remote_state.network.outputs.private_subnets
  control_plane_subnet_ids                 = data.terraform_remote_state.network.outputs.public_subnets
  authentication_mode                      = "API_AND_CONFIG_MAP"
  cluster_addons = {
    vpc-cni = {
      most_recent       = true
      before_compute    = true
      resolve_conflicts_on_update = "PRESERVE"
      service_account_role_arn = module.irsa-vpc-cni.iam_role_arn
      configuration_values = jsonencode({ env={
      ENABLE_PREFIX_DELEGATION           = "true"
        AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
        ENI_CONFIG_LABEL_DEF = "topology.kubernetes.io/zone"
        WARM_PREFIX_TARGET = "1"}})
    }
}
  eks_managed_node_group_defaults = {
    instance_types                 = ["m6a.large"]
    disk_size                      = 50
    ami_type                       = "AL2_x86_64"
    use_latest_ami_release_version = true
    ami_release_version            = "1.26.15-20240514"
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size = 50
          volume_type = "gp3"
        }
      }
    }
    name_prefix                = "eks-node"
    iam_role_attach_cni_policy = true

  }
  eks_managed_node_groups = var.eks_managed_node_groups
}

output "cluster_name" {
  value = module.eks.cluster_name
}
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}
output "oidc_provider" {
  value = module.eks.oidc_provider
}
output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
output "cluster_version" {
  value = module.eks.cluster_version
}