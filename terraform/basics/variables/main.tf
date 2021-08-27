resource "random_integer" "number" {
  min = var.random_min_value
  max = local.random_max_value
}