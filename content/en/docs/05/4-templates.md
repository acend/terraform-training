---
title: "5.4. Templates"
weight: 54
sectionnumber: 5.4
onlyWhen: azure
---


## Preparation

Create a new directory for this exercise:
```bash
mkdir $LAB_ROOT/advanced/templates
cd $LAB_ROOT/advanced/templates
```


## Step {{% param sectionnumber %}}.1: Multiline strings

Sometimes you'd like to construct multiline strings while avoiding `\n` escape sequences for readability.  
Terraform offers so called "heredoc" style string literals to achieve that. The full documentation can be found at
https://www.terraform.io/docs/language/expressions/strings.html

Create a new file named `variables.tf` and add the following content:

```terraform
variable "action" {
  default = "fun"
}
```

Create a new file named `outputs.tf` and add the following content:

```terraform
output "multiline_ugly" {
  value = <<EOT
Cloud
engineering
for ${var.action}!
EOT
}
```

This looks pretty ugly but does the job; create a multiline strings.  
To add indentation, use the sequence `<<-` to improve readability:

```terraform
output "multiline_pretty" {
  value = <<-EOT
          Cloud
          engineering
          for ${var.action}!
          EOT
}
```

Now run:

```bash
terraform init
terraform apply
terraform output -raw multiline_ugly
terraform output -raw multiline_pretty
```


## Step {{% param sectionnumber %}}.2: Template files

Templates can be rather large (ie. firewall config or cloud-init scripts) and bloat the Terraform code.  
For such use-cases the template is stored in a separate file and sourced using the `templatefile` function documented
at https://www.terraform.io/docs/language/functions/templatefile.html

We use a cloud-init template used for Gitlab runner deployments as an real-world example.

Create a new file named `cloud_init.yml.tpl` and add the following content:

```yaml
#cloud-config
package_upgrade: true
packages:
  - docker.io
write_files:
  - path: /etc/cron.d/cleanup_docker_images
    owner: root:root
    content: |
      0 22 * * * root docker system prune --volumes --force --all >/dev/null 2>&1
  - path: /etc/docker/daemon.json
    owner: root:root
    content: |
      { "data-root": "/mnt/docker" }
runcmd:
  - wget -O /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
  - chmod +x /usr/local/bin/gitlab-runner
  - useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
  - /usr/local/bin/gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
  - /usr/local/bin/gitlab-runner start
  - /usr/local/bin/gitlab-runner register
      --non-interactive
      --executor docker
      --docker-privileged
      --docker-image docker:latest
      --name ${gitlab_runner_id}
      --url ${gitlab_url}
      --registration-token ${gitlab_runner_token}
      --docker-volumes "/certs/client"
%{ if gitlab_tag_list != null ~}
      --tag-list ${gitlab_tag_list}
%{ endif ~}
```

As you can see, the template contains several variables and supports conditional expressions (if / endif) and
for-loops. 

In `outputs.tf` add the following output:

```terraform
output "cloud_init" {
  value = templatefile("cloud_init.yml.tpl", {
      gitlab_runner_id    = 1
      gitlab_url          = "https://foobar.com"
      gitlab_runner_token = "supersecret"
      gitlab_tag_list     = "linux,highmem"
    })
}
```

Now run:

```bash
terraform apply
terraform output -raw cloud_init
```


## Step {{% param sectionnumber %}}.3: Bonus: Cloud-init output

Cloud-init scripts passed as user-data on cloud platforms while provisioning a new VM, have a max size of 16kb. This is
almost always enough, but it is good practice to zip and base64 encode the content.  
Terraform offers a data source to simplify this process, `template_cloudinit_config` documented at 
https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config

Create a new file named `main.tf` and add the following content:

```terraform
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
```

In `outputs.tf` add the following output:

```terraform
output "user_data" {
  value = data.template_cloudinit_config.runner.rendered
}
```

Now run:

```bash
terraform apply
terraform output -raw user_data | base64 -d | gunzip -
```
