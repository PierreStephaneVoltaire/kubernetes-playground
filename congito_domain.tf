resource "aws_acm_certificate" "auth_cert" {
  provider          = aws.us-east-1
  domain_name       = "auth.${var.domain_name}"
  validation_method = "DNS"
}

resource "aws_route53_record" "auth_cert_validation" {
  provider = aws.us-east-1
  for_each = {
    for dvo in aws_acm_certificate.auth_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}


resource "aws_acm_certificate_validation" "auth_cert_validation" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.auth_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.auth_cert_validation : record.fqdn]
}

resource "aws_cognito_user_pool_domain" "this" {
  depends_on      = [aws_route53_record.auth_cert_validation]
  domain          = "auth.${var.domain_name}"
  certificate_arn = aws_acm_certificate.auth_cert.arn
  user_pool_id    = aws_cognito_user_pool.auth.id
}

resource "aws_route53_record" "subdomain-a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "auth.${var.domain_name}"
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_cognito_user_pool_domain.this.cloudfront_distribution_arn
    zone_id                = "Z2FDTNDATAQYW2"
  }
}