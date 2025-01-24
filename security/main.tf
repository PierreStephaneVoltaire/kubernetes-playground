output "cognito_endpoint" {
  value = aws_cognito_user_pool.auth.endpoint
}
output "argo_app_client_id" {
  value = aws_cognito_user_pool_client.auth.id
}
output "argo_app_client_secret" {
  value = aws_cognito_user_pool_client.auth.client_secret
}

output "jenkins_app_client_id" {
  value = aws_cognito_user_pool_client.jenkins_auth.id
}
output "jenkins__app_client_secret" {
  value = aws_cognito_user_pool_client.jenkins_auth.client_secret
}
