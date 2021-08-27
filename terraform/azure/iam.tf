data "azuread_group" "aks_admins" {
  display_name = var.aks.ad_admin_group
}