module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "~> 20.26"
  cluster_name                             = "${var.app_name}-cluster"
  cluster_version                          = var.cluster_version
  cluster_enabled_log_types                = []
  cluster_endpoint_public_access_cidrs     = var.allowed_ips
  node_iam_role_additional_policies        = { AmazonEBSCSIDriverPolicy = data.aws_iam_policy.AmazonEBSCSIDriverPolicy.arn, AmazonEKSLoadBalancingPolicy = data.aws_iam_policy.AmazonEKSLoadBalancingPolicy.arn, AmazonEKSCNIPolicy = data.aws_iam_policy.AmazonEKSCNIPolicy.arn, AmazonEKSWorkerNodePolicy = data.aws_iam_policy.AmazonEKSWorkerNodePolicy.arn, AmazonSSMManagedInstanceCore = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn, }
  iam_role_additional_policies             = { AmazonEKSServiceRolePolicy = data.aws_iam_policy.AmazonEKSClusterPolicy.arn, AmazonEKSServicePolicy = data.aws_iam_policy.AmazonEKSServicePolicy.arn, AmazonEKSVPCResourceController = data.aws_iam_policy.AmazonEKSVPCResourceController.arn }
  cluster_endpoint_public_access           = true
  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }
  enable_irsa                              = true
  cluster_service_ipv4_cidr                = var.cluster_service_ipv4_cidr
  enable_cluster_creator_admin_permissions = true
  vpc_id                                   = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids                               = data.terraform_remote_state.network.outputs.private_subnets
  control_plane_subnet_ids                 = data.terraform_remote_state.network.outputs.public_subnets
  authentication_mode                      = "API_AND_CONFIG_MAP"
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

