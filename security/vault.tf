locals {
  vault_domain = "vault.${var.domain_name}"
}
data "aws_region" "current" {}
resource "helm_release" "vault" {
  name             = "vault"
  namespace        = "vault"
  create_namespace = true
  chart            = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  version          = var.vault_version
  cleanup_on_fail  = true
  recreate_pods    = true
  values = [
    <<-EOF
    server:
      config: |
        listener "tcp" {
          address       = "0.0.0.0:8200"
        }
        storage "s3" {
          bucket         = "${aws_s3_bucket.vault_storage.bucket}"
        }
        seal "awskms" {
          region     = "${data.aws_region.current.name}"
          kms_key_id = "${aws_kms_key.vault_kms_key.arn}"
          endpoint = "kms.<KMS_KEY_REGION>.amazonaws.com"
        }
        ui = true
        disable_mlock = true
        log_level = "INFO"
      ingress:
        hosts:
          - host: vault.${var.domain_name}
            paths: []
        enabled: true
        annotations:
            kubernetes.io/ingress.class: "alb"
            alb.ingress.kubernetes.io/scheme: internet-facing
            alb.ingress.kubernetes.io/backend-protocol: HTTPS
            alb.ingress.kubernetes.io/target-type: ip
            alb.ingress.kubernetes.io/subnets: '${var.public_subnets_string}'
            alb.ingress.kubernetes.io/listen-ports : '[{"HTTPS":443}]'
            alb.ingress.kubernetes.io/certificate-arn: '${var.alb_cert_arn}'
      affinity: {}
      ha:
        enabled: false
    EOF
  ]
}
resource "aws_s3_bucket" "vault_storage" {
  bucket        = "${var.app_name}-vault-storage-${random_string.suffix.result}"
  force_destroy = true



}
resource "aws_s3_bucket_lifecycle_configuration" "versioning-bucket-config" {

  bucket = aws_s3_bucket.vault_storage.id

  rule {
    id = "version_cleanup"
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "vault" {
  bucket = aws_s3_bucket.vault_storage.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.vault_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "vault" {
  bucket = aws_s3_bucket.vault_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}



resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "aws_iam_role" "vault_role" {
  name               = "${var.app_name}-vault-role"
  assume_role_policy = data.aws_iam_policy_document.vault_assume_role_policy.json
}

data "aws_iam_policy_document" "vault_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "vault_kms_policy" {
  name   = "${var.app_name}VaultKMS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = aws_kms_key.vault_kms_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vault_policy_attach" {
  role       = aws_iam_role.vault_role.name
  policy_arn = aws_iam_policy.vault_kms_policy.arn
}

resource "aws_kms_key" "vault_kms_key" {
  enable_key_rotation     = true
  policy = data.aws_iam_policy_document.kms_policy.json

}

data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid    = "root"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "vault"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.vault_role.arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}



resource "vault_auth_backend" "oidc" {
  type = "oidc"
  path = "oidc"
}


resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = "sleep 120"
  }
  depends_on = [helm_release.vault]
}
data "aws_lbs" "vault" {
  depends_on = [null_resource.wait]
  tags = {
    "ingress.k8s.aws/stack" = "vault/vault"
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




