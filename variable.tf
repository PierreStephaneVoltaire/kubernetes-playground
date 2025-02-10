variable "app_name" {
  type    = string
  default = "infra"
}
variable "tags" {
  type = map(string)
}
variable "domain_name" {
  type = string
}

variable "cluster_service_ipv4_cidr" {
  type = string
}

variable "cluster_version" {
  type = string
}
variable "contact" {
  type = string
}
variable "eks_managed_node_groups" {
  type = map(object({
    ebs_optimized           = bool
    enable_monitoring       = bool
    node_repair_config =object({enabled:bool})
    disk_size      = number
    capacity_type  = optional(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    spot_price     = optional(number)
    instance_types = optional(list(string))
  }))
}

variable "allowed_ips" {
  type      = list(string)
  sensitive = true
}

variable "bucket" {
  type = string
}
variable "network_key" {
  type = string
}