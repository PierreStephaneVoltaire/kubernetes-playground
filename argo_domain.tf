resource "aws_acm_certificate" "argocd_cert" {
  domain_name       = "argocd.${var.domain_name}"
  validation_method = "DNS"

  tags = {
    Name = "argocd-cert"
  }
}

resource "aws_route53_record" "argocd_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.argocd_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

data "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_acm_certificate_validation" "argocd_cert_validation" {
  certificate_arn         = aws_acm_certificate.argocd_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.argocd_cert_validation : record.fqdn]
}
resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = "dir"
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
  name    = "argocd.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.argo.dns_name
    zone_id                = data.aws_lb.argo.zone_id
    evaluate_target_health = true
  }
}