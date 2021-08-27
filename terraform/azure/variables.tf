locals {
  infix = "${var.purpose}-${var.environment}"
}

variable "subscription_id" {}
variable "purpose" {}
variable "environment" {}
variable "location" {}
variable "network_cidrs" {
  default = {
    vnet   = "10.0.0.0/8"
    subnet = "10.1.0.0/16"
  }
  type = object({
    vnet   = string
    subnet = string
  })
}
variable "aks" {
  type = object({
    // az aks get-versions --location westeurope -o table
    kubernetes_version    = string
    availability_zones    = list(number)
    log_retention_in_days = number
    ad_admin_group        = string
    node_pool = object({
      vm_size    = string
      node_count = number
    })
  })
}