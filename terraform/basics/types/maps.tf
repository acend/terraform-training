locals {
  tags = {
    env = "prod"
    app = "nginx"
  }
  extra_tags = {
    plattform = "azure"
  }
}

output "tag_list" {
  value = keys(local.tags)
}

output "full_tags" {
  value = merge(local.tags, local.extra_tags)
}