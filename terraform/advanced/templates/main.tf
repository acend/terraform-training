data "template_cloudinit_config" "runner" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("cloud_init.yml.tpl", {
      gitlab_runner_id    = 1
      gitlab_url          = "https://foobar.com"
      gitlab_runner_token = "supersecret"
      gitlab_tag_list     = "linux,highmem"
    })
  }
}
