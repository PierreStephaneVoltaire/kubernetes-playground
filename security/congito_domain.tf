locals {
  domain = replace(var.domain_name, ".", "")

}

resource "aws_cognito_user_pool_domain" "this" {

  domain       = local.domain
  user_pool_id = aws_cognito_user_pool.auth.id
}

