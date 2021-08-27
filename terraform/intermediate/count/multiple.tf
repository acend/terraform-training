resource "random_uuid" "ids" {
  count = 8
}

output "ids" {
  value = random_uuid.ids.*.result
}