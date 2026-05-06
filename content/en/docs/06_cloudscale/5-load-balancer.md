---
title: "10.5. Load Balancer"
weight: 105
sectionnumber: 10.5
onlyWhen: cloudscale
---


## Preparation

Continue in the same working directory:

```bash
cd $LAB_ROOT/cloudscale
```


## Step {{% param sectionnumber %}}.1: Create the Load Balancer Stack

A cloudscale.ch load balancer consists of several connected resources:

| Resource | Purpose |
| --- | --- |
| `cloudscale_load_balancer` | The physical LB instance with a public VIP |
| `cloudscale_load_balancer_pool` | A group of backend servers and the balancing algorithm |
| `cloudscale_load_balancer_listener` | The public-facing port that accepts incoming traffic |
| `cloudscale_load_balancer_pool_member` | One entry per backend server (IP + port) |
| `cloudscale_load_balancer_health_monitor` | Periodic health checks to detect failed members |

Create a new file `lb.tf`:

```terraform
resource "cloudscale_load_balancer" "web" {
  name         = "${local.prefix}-lb"
  flavor_slug  = "lb-standard"
  zone_slug    = var.zone
}

resource "cloudscale_load_balancer_pool" "web" {
  name                  = "${local.prefix}-pool"
  algorithm             = "round_robin"
  protocol              = "tcp"
  load_balancer_uuid    = cloudscale_load_balancer.web.id
}

resource "cloudscale_load_balancer_listener" "web" {
  name          = "${local.prefix}-listener"
  protocol      = "tcp"
  protocol_port = 80
  pool_uuid     = cloudscale_load_balancer_pool.web.id
}

resource "cloudscale_load_balancer_pool_member" "web" {
  for_each = var.web_servers

  name          = "${local.prefix}-member-${each.key}"
  pool_uuid     = cloudscale_load_balancer_pool.web.id
  protocol_port = 80
  address       = each.value.private_ip
  subnet_uuid   = cloudscale_subnet.backend.id
}

resource "cloudscale_load_balancer_health_monitor" "web" {
  pool_uuid      = cloudscale_load_balancer_pool.web.id
  type           = "http"
  http_url_path  = "/"
  http_version   = "1.1"
  http_host      = "localhost"
}
```


### Explanation


#### Load balancer and pool

The `lb-standard` flavor is the default load balancer size for cloudscale.ch. When
created without explicit `vip_addresses`, the load balancer is assigned a **public IPv4
and IPv6 VIP** automatically.

The pool algorithm `round_robin` distributes each new TCP connection to the next member in
rotation — exactly what you need to demonstrate that both web servers receive traffic.


#### Pool members

The `for_each = var.web_servers` pattern used here mirrors lab 10.4: one pool member is
created per web server entry in the map. Each member references:

* `address` — the web server's private IP (`10.0.1.11` / `10.0.1.12`)
* `subnet_uuid` — the private subnet, so the load balancer can route traffic to it
* `protocol_port = 80` — nginx listens on port 80

By pointing pool members at the **private IPs**, all HTTP traffic between the load
balancer and the web servers stays within the private network.


#### Health monitor

An HTTP health monitor polls `GET /` on port 80 of each member. If a member fails two
consecutive checks, the load balancer stops sending traffic to it until it recovers. This
makes the load balancer self-healing: a failed web server is automatically removed from
the rotation without any manual intervention.


## Step {{% param sectionnumber %}}.2: Expose the Load Balancer IP

Add the LB VIP address to `outputs.tf`:

```terraform
output "web_public_ips" {
  description = "Public IPv4 addresses of all web servers, keyed by server name."
  value       = { for k, v in cloudscale_server.web : k => v.public_ipv4_address }
}

output "backend_private_ip" {
  description = "The private IPv4 address of the backend server."
  value       = cloudscale_server.backend.private_ipv4_address
}

output "lb_public_ip" {
  description = "The public IPv4 VIP address of the load balancer."
  value       = one([for vip in cloudscale_load_balancer.web.vip_addresses : vip.address if vip.version == 4])
}
```


### Explanation

`cloudscale_load_balancer.web.vip_addresses` is a list containing one entry per IP
version. The expression `[for vip in ... : vip.address if vip.version == 4]` filters to
only the IPv4 VIP. The `one()` built-in unwraps the single-element list into a plain
string, making it easy to use with `terraform output -raw`.


## Step {{% param sectionnumber %}}.3: Apply the Changes

```bash
terraform apply
```

The plan shows five new resources (load balancer, pool, listener, two pool members, health
monitor) and no changes to existing servers.

```text
Plan: 6 to add, 0 to change, 0 to destroy.
```

Confirm with `yes`.

The apply may take 60–90 seconds because provisioning a load balancer involves allocating
dedicated hardware.


## Step {{% param sectionnumber %}}.4: Wait for Health Checks to Pass

After the apply completes, the load balancer needs a moment to perform the initial health
checks against both web servers. Retrieve the VIP address:

```bash
terraform output lb_public_ip
```

Give it 30–60 seconds, then check that the load balancer can reach both members by sending
a few requests. If you see `Connection refused` immediately after the apply, wait a moment
and retry.


## Step {{% param sectionnumber %}}.5: Demonstrate Round-Robin Load Balancing

Send six consecutive requests to the load balancer VIP and observe which server handles
each one:

```bash
LB_IP=$(terraform output -raw lb_public_ip)
for i in {1..6}; do
  curl -s "http://${LB_IP}" | grep -oP '(?<=Hostname:</b> )[^<]+'
done
```

Expected output — the hostname alternates between the two servers:

```text
Hostname: alpdeploy-jane-web-01
Hostname: alpdeploy-jane-web-02
Hostname: alpdeploy-jane-web-01
Hostname: alpdeploy-jane-web-02
Hostname: alpdeploy-jane-web-01
Hostname: alpdeploy-jane-web-02
```

{{% alert title="Round-robin confirmed" color="secondary" %}}
Each request is served by a different web server in strict rotation. Because each server's
nginx page was generated from the cloudscale metadata service at boot time, the hostname
embedded in the HTML is unique per server — making the round-robin behaviour directly
visible.
{{% /alert %}}

{{% details title="Hints" %}}
If all six responses show the same hostname, your HTTP client may be reusing a TCP
connection (keep-alive). Force a new connection each time:

```bash
LB_IP=$(terraform output -raw lb_public_ip)
for i in {1..6}; do
  curl -s --no-keepalive "http://${LB_IP}" | grep -oP '(?<=Hostname:</b> )[^<]+'
done
```

If `lb_public_ip` is still empty after the apply, check `terraform show` or the
cloudscale control panel for the assigned VIP address.
{{% /details %}}


## Cleanup

When you are done with the workshop, destroy all resources to avoid ongoing charges:

```bash
terraform destroy
```

{{% alert title="Destroy all resources" color="secondary" %}}
The `terraform destroy` command removes **all** resources managed in this working
directory — servers, volumes, network, and load balancer. Confirm only when you are sure
you no longer need the environment.
{{% /alert %}}
