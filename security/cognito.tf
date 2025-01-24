
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
  callback_urls       = ["${var.argo_domain}/auth/callback"]
  logout_urls         = ["${var.argo_domain}/auth/logout"]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "phone", "openid"]
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
  role_arn     = aws_iam_role.argo_authenticated_role.arn
}



resource "aws_iam_role" "argo_authenticated_role" {
  name = "argo_authenticated_role"
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
resource "random_password" "argo_password" {
  for_each    = var.users
  length      = 12
  min_special = 4
  special     = true
  numeric     = true
  min_numeric = 2
}

resource "aws_cognito_user" "user" {
  for_each       = var.users
  user_pool_id   = aws_cognito_user_pool.auth.id
  username       = each.value.email
  password       = random_password.argo_password[each.key].result
  message_action = "SUPPRESS"
  attributes = {
    email          = each.value.email
    email_verified = true
  }
}

resource "aws_cognito_user_in_group" "argo_user_groups" {
  for_each     = aws_cognito_user.user
  user_pool_id = aws_cognito_user_pool.auth.id
  group_name   = aws_cognito_user_group.argo.name
  username     = each.value.username
}

resource "kubernetes_secret" "user_credentials" {
  for_each = aws_cognito_user.user
  metadata {
    name      = "credentials-${each.key}"
    namespace = "argocd"
  }

  data = {
    username = base64encode(each.value.username)
    password = base64encode(each.value.password)
  }

  type = "kubernetes.io/basic-auth"
}