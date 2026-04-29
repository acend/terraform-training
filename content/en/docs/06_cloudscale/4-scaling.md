---
title: "10.4. Scaling Out"
weight: 104
sectionnumber: 10.4
onlyWhen: cloudscale
---


## Preparation

Continue in the same working directory:

```bash
cd $LAB_ROOT/cloudscale
```


## Step {{% param sectionnumber %}}.1: Add a Server Group for Anti-Affinity

Running multiple web servers on the same physical host defeats the purpose of redundancy.
cloudscale.ch provides **server groups** with an `anti-affinity` policy to ensure members
are placed on different physical hypervisors.

Add the following resource to `main.tf` (at the top, after the `locals` block):

```terraform
resource "cloudscale_server_group" "web" {
  name      = "${local.prefix}-web"
  type      = "anti-affinity"
  zone_slug = var.zone
}
```


### Explanation

The `anti-affinity` server group type is currently the only supported type in the
cloudscale provider. When two or more servers are members of the same anti-affinity group,
cloudscale's scheduler guarantees they are placed on **different physical hosts**. This
protects against a single hardware failure taking down all web servers simultaneously.


## Step {{% param sectionnumber %}}.2: Declare the Web Server Map Variable

Instead of a single web server, you will now manage a **map of servers** using `for_each`.
Add the following variable to `variables.tf`:

```terraform
variable "web_servers" {
  description = "Map of web server identifiers to their private network configuration."
  type = map(object({
    private_ip = string
  }))
  default = {
    web-01 = { private_ip = "10.0.1.11" }
    web-02 = { private_ip = "10.0.1.12" }
  }
}
```


### Explanation

Using a `map(object(...))` variable for `for_each` has several advantages over a list with
`count`:

* Each server has a **stable key** (`web-01`, `web-02`). Adding or removing a server only
  affects that one entry — unlike `count`, which reindexes all instances.
* The map value carries per-server configuration (private IP) alongside the key.
* The server names, private IPs, and volume names all derive from `each.key` and
  `each.value`, keeping things consistent without duplication.


## Step {{% param sectionnumber %}}.3: Convert the Web Server to `for_each`

Replace the single `cloudscale_server.web` and `cloudscale_volume.web_data` resources in
`main.tf` with `for_each` versions. The full updated `main.tf` is:

```terraform
locals {
  prefix = "alpdeploy-${var.username}"
}

resource "cloudscale_server_group" "web" {
  name      = "${local.prefix}-web"
  type      = "anti-affinity"
  zone_slug = var.zone
}

resource "cloudscale_server" "web" {
  for_each = var.web_servers

  name             = "${local.prefix}-${each.key}"
  flavor_slug      = "flex-4-2"
  image_slug       = "debian-13"
  zone_slug        = var.zone
  volume_size_gb   = 10
  ssh_keys         = [var.ssh_public_key]
  user_data        = file("${path.module}/cloud-init/web.yaml")
  server_group_ids = [cloudscale_server_group.web.id]

  interfaces {
    type = "public"
  }

  interfaces {
    type = "private"
    addresses {
      subnet_uuid = cloudscale_subnet.backend.id
      address     = each.value.private_ip
    }
  }
}

resource "cloudscale_volume" "web_data" {
  for_each = var.web_servers

  name         = "${local.prefix}-${each.key}-data"
  zone_slug    = var.zone
  size_gb      = 50
  type         = "ssd"
  server_uuids = [cloudscale_server.web[each.key].id]
}
```


### Explanation

When `for_each` is used, Terraform creates one resource instance per map entry. Each
instance is addressed by its key:

| Terraform address | Server name |
| --- | --- |
| `cloudscale_server.web["web-01"]` | `alpdeploy-jane-web-01` |
| `cloudscale_server.web["web-02"]` | `alpdeploy-jane-web-02` |

Inside the resource block, `each.key` holds the map key (`web-01`, `web-02`) and
`each.value` holds the corresponding object (`{ private_ip = "10.0.1.11" }`).

The `server_group_ids` argument adds both servers to the anti-affinity group. cloudscale
will schedule them on different physical hosts.


## Step {{% param sectionnumber %}}.4: Update the Outputs

Replace `outputs.tf` to return a map of public IPs for all web servers:

```terraform
output "web_public_ips" {
  description = "Public IPv4 addresses of all web servers, keyed by server name."
  value       = { for k, v in cloudscale_server.web : k => v.public_ipv4_address }
}

output "backend_private_ip" {
  description = "The private IPv4 address of the backend server."
  value       = cloudscale_server.backend.private_ipv4_address
}
```


## Step {{% param sectionnumber %}}.5: Apply the Changes

```bash
terraform apply
```

The plan shows:

* `-/+` for `cloudscale_server.web` (the old single server is replaced by two new ones
  with `for_each` keys and `server_group_ids`)
* `+` for `cloudscale_server_group.web`
* `+` for `cloudscale_server.web["web-02"]` and `cloudscale_volume.web_data["web-02"]`
* `~` for `cloudscale_volume.web_data["web-01"]` (re-attached)

Confirm with `yes`.


## Step {{% param sectionnumber %}}.6: Verify Both Servers

After cloud-init finishes on both servers, retrieve the IP map and curl each one:

```bash
terraform output -json web_public_ips
```

Expected output (example):

```text
{
  "web-01": "185.98.123.45",
  "web-02": "185.98.123.67"
}
```

Test each server individually:

```bash
curl http://$(terraform output -json web_public_ips | python3 -c "import json,sys; print(json.load(sys.stdin)['web-01'])")
curl http://$(terraform output -json web_public_ips | python3 -c "import json,sys; print(json.load(sys.stdin)['web-02'])")
```

Each response should show a different `Hostname:` value (`alpdeploy-jane-web-01` and
`alpdeploy-jane-web-02`), confirming that two independent servers are running. The next
lab will put a load balancer in front of them so that clients reach them through a single
IP.
