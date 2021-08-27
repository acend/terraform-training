locals {
  counter = 5
}

output "counter" {
  value = "Counter is ${local.counter}"
}
