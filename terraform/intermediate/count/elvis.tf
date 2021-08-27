locals {
  create_password = false
}

resource "random_password" "optional_password" {
  count  = local.create_password ? 1 : 0
  length = 16
}

output "optional_password" {
  sensitive = true
  value     = local.create_password ? random_password.optional_password.0.result : null
}