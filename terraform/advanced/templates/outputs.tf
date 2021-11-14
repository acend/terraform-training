output "multiline_ugly" {
  value = <<EOT
Cloud
engineering
for ${var.action}!
EOT
}

output "multiline_pretty" {
  value = <<-EOT
          Cloud
          engineering
          for ${var.action}!
          EOT
}

output "cloud_init" {
  value = templatefile("cloud_init.yml.tpl", {
    gitlab_runner_id    = 1
    gitlab_url          = "https://foobar.com"
    gitlab_runner_token = "supersecret"
    gitlab_tag_list     = "linux,highmem"
  })
}

output "user_data" {
  value = data.template_cloudinit_config.runner.rendered
}