
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