locals {
  vault_domain = "vault.${var.domain_name}"
}
data "aws_region" "current" {}
resource "helm_release" "vault" {
  name             = "vault"
  namespace        = kubernetes_namespace.vault.metadata[0].name
  create_namespace = false
  chart            = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  version          = var.vault_version
  cleanup_on_fail  = true
  set {
    name  = "server.serviceAccount.create"
    value = "false"
  }


  values = [
    templatefile("${path.module}/vault.yaml",
      { domain_name           = var.domain_name,
        public_subnets_string = var.public_subnets_string,
        alb_cert_arn          = var.alb_cert_arn,
        region                = data.aws_region.current.name
        sa                    = kubernetes_service_account.vault.metadata[0].name
        key                   = aws_kms_key.vault_kms_key.arn
    })
  ]
}


data "aws_caller_identity" "current" {}




resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = "sleep 120"
  }
  depends_on = [helm_release.vault]
}
data "aws_lbs" "vault" {
  depends_on = [null_resource.wait]
  tags = {
    "ingress.k8s.aws/stack" = "${kubernetes_namespace.vault.metadata[0].name}/vault"
  }
}
data "aws_route53_zone" "main" {
  name = var.domain_name
}

data "aws_lb" "vault" {
  arn = one(data.aws_lbs.vault.arns)
}
resource "aws_route53_record" "vaultcd_alb" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.vault_domain
  type    = "A"
  alias {
    name                   = data.aws_lb.vault.dns_name
    zone_id                = data.aws_lb.vault.zone_id
    evaluate_target_health = true
  }
}




