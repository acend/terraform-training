locals {
  fibonacci = [0, 1, 1, 2, 3, 5, 8, 13]
}

output "element_5" {
  value = local.fibonacci.5 // or local.fibonacci[5]
}

output "fibonacci" {
  value = join("/", local.fibonacci)
}