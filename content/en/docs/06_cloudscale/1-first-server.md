---
title: "10.1. The First Server"
weight: 101
sectionnumber: 10.1
onlyWhen: cloudscale
---


## Preparation

Continue in the cloudscale working directory created in the chapter preparation:

```bash
cd $LAB_ROOT/cloudscale
```


## Step {{% param sectionnumber %}}.1: Configure the Terraform Provider

Create a `versions.tf` file to pin the cloudscale provider version:

```terraform
terraform {
  required_version = ">= 1.12.0"

  required_providers {
    cloudscale = {
      source  = "cloudscale-ch/cloudscale"
      version = "~> 5.0"
    }
  }
}
```


### Explanation

The [cloudscale Terraform provider](https://registry.terraform.io/providers/cloudscale-ch/cloudscale)
is maintained by cloudscale.ch and mirrors the full cloudscale.ch REST API. Setting
`version = "~> 5.0"` pins to the `5.x` series and allows patch-level upgrades while
preventing breaking changes from a future major version.


## Step {{% param sectionnumber %}}.2: Declare Variables

Create a `variables.tf` file:

```terraform
variable "username" {
  description = "Your workshop username. Used as a prefix for all resource names."
  type        = string
}

variable "zone" {
  description = "The cloudscale.ch zone to deploy resources in (lpg1 or rma1)."
  type        = string
  default     = "lpg1"
}

variable "ssh_public_key" {
  description = "Content of your SSH public key (e.g. the output of: cat ~/.ssh/id_ed25519.pub)."
  type        = string
}
```

Create a `terraform.tfvars` file and fill in your values:

```terraform
username       = "YOUR_USERNAME"
zone           = "lpg1"
ssh_public_key = "<your-ssh-public-key>"
```

{{% alert title="Note" color="secondary" %}}
Replace `YOUR_USERNAME` with your assigned workshop username and paste your actual SSH
public key string as the value for `ssh_public_key`.
{{% /alert %}}


## Step {{% param sectionnumber %}}.3: Create the cloud-init Script

The web server will run nginx. Its `index.html` page is generated at boot time by querying
the cloudscale **metadata service** — a local HTTP endpoint available on every cloudscale
VM at `169.254.169.254`.

Create the directory and file `cloud-init/web.yaml`:

```bash
mkdir -p cloud-init
```

```yaml
#cloud-config
package_update: true
packages:
  - nginx
  - curl
runcmd:
  - curl -sf --retry 5 --retry-delay 2 http://169.254.169.254/openstack/latest/meta_data.json -o /tmp/meta.json
  - python3 -c "import json; d=json.load(open('/tmp/meta.json')); open('/var/www/html/index.html','w').write('<html><body><h1>AlpDeploy</h1><p><b>Hostname:</b> '+d.get('hostname','?')+'</p><p><b>Zone:</b> '+d.get('availability_zone','?')+'</p></body></html>\n')"
  - systemctl enable nginx
  - systemctl start nginx
```


### Explanation

The cloudscale metadata service implements the **OpenStack metadata format**. The endpoint
`http://169.254.169.254/openstack/latest/meta_data.json` returns a JSON document that
includes:

| Field | Example value | Meaning |
| --- | --- | --- |
| `hostname` | `alpdeploy-jane-web` | The server name |
| `availability_zone` | `lpg1` | The zone the server lives in |
| `uuid` | `abcd-1234-...` | The server's unique ID |

The `runcmd` cloud-init module runs shell commands once at first boot, after packages are
installed. Using the Python one-liner avoids shell-level quoting issues with heredocs
inside Terraform configuration.


## Step {{% param sectionnumber %}}.4: Define the Server Resource

Create `main.tf`:

```terraform
provider "cloudscale" {
  # Authentication is done via the CLOUDSCALE_API_TOKEN environment variable.
}

locals {
  prefix = "alpdeploy-${var.username}"
}

resource "cloudscale_server" "web" {
  name           = "${local.prefix}-web"
  flavor_slug    = "flex-4-2"
  image_slug     = "debian-13"
  zone_slug      = var.zone
  volume_size_gb = 10
  ssh_keys       = [var.ssh_public_key]
  user_data      = file("${path.module}/cloud-init/web.yaml")
}
```


### Explanation

| Argument | Value | Notes |
| --- | --- | --- |
| `flavor_slug` | `flex-4-2` | 2 vCPUs, 4 GB RAM |
| `image_slug` | `debian-13` | Debian 13 (Trixie) — default user: `debian` |
| `zone_slug` | variable | Either `lpg1` (Lupfig AG) or `rma1` (Rümlang ZH) |
| `volume_size_gb` | `10` | Root disk size in GiB |
| `ssh_keys` | list of key strings | Key content, not a path |
| `user_data` | cloud-init YAML | Injected at first boot |

When no `interfaces` block is specified, the server gets a **public** IPv4 and IPv6
address on the cloudscale internet network by default.

The provider reads the API token exclusively from the `CLOUDSCALE_API_TOKEN` environment
variable. This keeps credentials out of your Terraform code and state file.


## Step {{% param sectionnumber %}}.5: Declare Outputs

Create `outputs.tf`:

```terraform
output "web_public_ip" {
  description = "The public IPv4 address of the web server."
  value       = cloudscale_server.web.public_ipv4_address
}
```


## Step {{% param sectionnumber %}}.6: Deploy

Initialise the working directory and apply:

```bash
terraform init
terraform apply
```

Terraform will display an execution plan showing one resource to create. Confirm with
`yes`.

After the apply completes, retrieve the public IP:

```bash
terraform output web_public_ip
```

Expected output (example):

```text
"185.98.123.45"
```


## Step {{% param sectionnumber %}}.7: Verify the Web Server

Cloud-init takes about 60–90 seconds to install nginx and generate the page. Once it has
finished, `curl` the IP:

```bash
curl http://$(terraform output -raw web_public_ip)
```

Expected output:

```text
<html><body><h1>AlpDeploy</h1><p><b>Hostname:</b> alpdeploy-jane-web</p><p><b>Zone:</b> lpg1</p></body></html>
```

You can also SSH into the server to explore it:

```bash
ssh debian@$(terraform output -raw web_public_ip)
```

{{% details title="Hints" %}}
If `curl` times out, cloud-init is probably still running. Check progress with:

```bash
ssh debian@$(terraform output -raw web_public_ip) cloud-init status --wait
```

{{% /details %}}
