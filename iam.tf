module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.39.0"
  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.AmazonEBSCSIDriverPolicy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}
data "aws_iam_policy" "AmazonEKSCNIPolicy" {
  name = "AmazonEKS_CNI_Policy"
}
data "aws_iam_policy" "AmazonEKSWorkerNodePolicy" {
  name = "AmazonEKSWorkerNodePolicy"
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  name = "AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "AmazonEKSLoadBalancingPolicy" {
  name = "AmazonEKSLoadBalancingPolicy"
}

data "aws_iam_policy" "AmazonEBSCSIDriverPolicy" {
  name = "AmazonEBSCSIDriverPolicy"
}
data "aws_iam_policy" "AmazonEKSServicePolicy" {
  name = "AmazonEKSServicePolicy"
}
data "aws_iam_policy" "AmazonEKSClusterPolicy" {
  name = "AmazonEKSServicePolicy"
}
data "aws_iam_policy" "AmazonEKSVPCResourceController" {
  name = "AmazonEKSVPCResourceController"
}