variable "app_name" {
  type = string
}
variable "tags" {
  type = map(string)
}
variable "argo_domain" {
  type = string
}
variable "domain_name" {
  type = string
}
variable "allowed_ips" {
  type      = list(string)
  sensitive = true
}
variable "argo_users" {
  type = map(object({ email = string }))
}
variable "vault_version" {
  type = string
}
variable "public_subnets_string" {
  type = string
}
variable "alb_cert_arn" {
  type = string
}