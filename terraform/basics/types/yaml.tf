locals {
  yaml_file = yamldecode(file("project.yaml"))
}

output "app" {
  value = local.yaml_file.components.0.metadata.annotations.app
}