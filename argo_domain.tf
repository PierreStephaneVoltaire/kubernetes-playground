locals {
  argo_domain = "argocd.${var.domain_name}"
}

data "aws_route53_zone" "main" {
  name = var.domain_name
}


resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = "sleep 120"
  }
  depends_on = [module.eks_blueprints_addons]
}
data "aws_lbs" "argo" {
  depends_on = [null_resource.wait]
  tags = {
    "ingress.k8s.aws/stack" = "argocd/argo-cd-argocd-server"
  }
}
data "aws_lb" "argo" {
  arn = one(data.aws_lbs.argo.arns)
}
resource "aws_route53_record" "argocd_alb" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.argo_domain
  type    = "A"
  alias {
    name                   = data.aws_lb.argo.dns_name
    zone_id                = data.aws_lb.argo.zone_id
    evaluate_target_health = true
  }
}