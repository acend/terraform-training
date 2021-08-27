subscription_id = "c1b34118-6a8f-4348-88c2-b0b1f7350f04"
purpose         = "lab"
environment     = "dev"
location        = "westeurope"
aks = {
  kubernetes_version    = "1.21.2"
  availability_zones    = [1, 2, 3]
  log_retention_in_days = 30
  ad_admin_group        = "students"
  node_pool = {
    node_count = 2
    vm_size    = "Standard_B2ms"
  }
}