
resource "aws_cognito_user_pool" "auth" {
  name                     = "${var.app_name}-user-pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

}
resource "aws_cognito_user_pool_client" "auth" {
  name                = "${var.app_name}-client"
  user_pool_id        = aws_cognito_user_pool.auth.id
  generate_secret     = true
  explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
  callback_urls       = ["https://auth.${var.domain_name}/callback"]
  logout_urls         = ["https://auth.${var.domain_name}/logout"]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "phone"]
  supported_identity_providers         = ["COGNITO"]
}
resource "aws_cognito_identity_pool" "argo_identity_pool" {
  identity_pool_name               = "${var.app_name}-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    provider_name = aws_cognito_user_pool.auth.endpoint
    client_id     = aws_cognito_user_pool_client.auth.id
  }
}


resource "aws_cognito_user_group" "argo" {
  name         = "${var.app_name}-argo-group"
  user_pool_id = aws_cognito_user_pool.auth.id
  role_arn = aws_iam_role.argo_authenticated_role.arn
}

data "aws_iam_policy_document" "group_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = ["us-east-1:12345678-dead-beef-cafe-123456790ab"]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["authenticated"]
    }
  }
}

resource "aws_iam_role" "argo_authenticated_role" {
  name               = "argo_authenticated_role"
  assume_role_policy = data.aws_iam_policy_document.group_role.json
}

resource "aws_iam_role" "authenticated_role" {
  name = "argo-authenticated-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.argo_identity_pool.id
          }
        }
      }
    ]
  })
}
