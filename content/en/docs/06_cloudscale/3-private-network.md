---
title: "10.3. Private Network"
weight: 103
sectionnumber: 10.3
onlyWhen: cloudscale
---


## Preparation

Continue in the same working directory:

```bash
cd $LAB_ROOT/cloudscale
```


## Step {{% param sectionnumber %}}.1: Create a Private Network and Subnet

AlpDeploy's backend service should not be exposed to the internet. You will create an
isolated private network and place a dedicated backend server on it — only reachable from
the web tier.

Create a new file `network.tf`:

```terraform
resource "cloudscale_network" "backend" {
  name                    = "${local.prefix}-backend"
  zone_slug               = var.zone
  auto_create_ipv4_subnet = false
}

resource "cloudscale_subnet" "backend" {
  cidr         = "10.0.1.0/24"
  network_uuid = cloudscale_network.backend.id
  dns_servers  = ["8.8.8.8", "8.8.4.4"]
}
```


### Explanation

| Resource | Purpose |
| --- | --- |
| `cloudscale_network` | An isolated Layer 2 network segment |
| `cloudscale_subnet` | An IP address range (CIDR) on top of the network |

Setting `auto_create_ipv4_subnet = false` prevents cloudscale from automatically creating
a default subnet so that we can define our own CIDR (`10.0.1.0/24`).

cloudscale assigns DHCP addresses from approximately `.101` to `.254` within the subnet.
Addresses in the lower part of the range (`.1` to `.100`) are available for static
assignment — which we will use for the backend server.


## Step {{% param sectionnumber %}}.2: Add the Backend Server cloud-init Script

The backend server runs a minimal Python HTTP API that returns its hostname in JSON. Create
`cloud-init/backend.yaml`:

```yaml
#cloud-config
packages:
  - python3
write_files:
  - path: /opt/backend.py
    permissions: '0755'
    content: |
      #!/usr/bin/env python3
      from http.server import HTTPServer, BaseHTTPRequestHandler
      import socket
      import json

      class Handler(BaseHTTPRequestHandler):
          def log_message(self, *args):
              pass

          def do_GET(self):
              body = json.dumps({"status": "ok", "host": socket.gethostname()}).encode()
              self.send_response(200)
              self.send_header("Content-Type", "application/json")
              self.end_headers()
              self.wfile.write(body)

      HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
  - path: /etc/systemd/system/backend.service
    content: |
      [Unit]
      Description=AlpDeploy Backend API
      After=network.target

      [Service]
      ExecStart=/usr/bin/python3 /opt/backend.py
      Restart=always

      [Install]
      WantedBy=multi-user.target
runcmd:
  - systemctl daemon-reload
  - systemctl enable backend
  - systemctl start backend
```


## Step {{% param sectionnumber %}}.3: Add the Backend Server Resource

Create `backend.tf`:

```terraform
resource "cloudscale_server" "backend" {
  name           = "${local.prefix}-backend"
  flavor_slug    = "flex-4-1"
  image_slug     = "debian-13"
  zone_slug      = var.zone
  volume_size_gb = 10
  ssh_keys       = [var.ssh_public_key]
  user_data      = file("${path.module}/cloud-init/backend.yaml")

  interfaces {
    type = "private"
    addresses {
      subnet_uuid = cloudscale_subnet.backend.id
      address     = "10.0.1.10"
    }
  }
}
```


### Explanation

The backend server has **only a private interface** — it is completely isolated from the
internet. The static address `10.0.1.10` is assigned explicitly so that the web server's
cloud-init can reach the backend at a known address.

The `flex-4-1` flavor (1 vCPU, 4 GB RAM) is sufficient for the small Python API.

{{% alert title="No public IP" color="secondary" %}}
Because the backend server has no public interface, you cannot SSH into it directly from
your workstation. To debug, SSH to the web server first, then jump to the backend from
there using its private address `10.0.1.10`.
{{% /alert %}}


## Step {{% param sectionnumber %}}.4: Update the Web Server

The web server now needs both a **public interface** (to serve visitors) and a **private
interface** (to reach the backend). Its cloud-init page is also updated to include the
backend response.

Update `cloud-init/web.yaml`:

```yaml
#cloud-config
package_update: true
packages:
  - nginx
  - curl
runcmd:
  - curl -sf --retry 5 --retry-delay 2 http://169.254.169.254/openstack/latest/meta_data.json -o /tmp/meta.json
  - curl -sf --retry 10 --retry-delay 3 http://10.0.1.10:8080 -o /tmp/backend.json || echo '{"status":"unreachable","host":"?"}' > /tmp/backend.json
  - python3 -c "import json; d=json.load(open('/tmp/meta.json')); b=json.load(open('/tmp/backend.json')); open('/var/www/html/index.html','w').write('<html><body><h1>AlpDeploy</h1><p><b>Hostname:</b> '+d.get('hostname','?')+'</p><p><b>Zone:</b> '+d.get('availability_zone','?')+'</p><p><b>Backend:</b> '+b.get('host','?')+'</p></body></html>\n')"
  - systemctl enable nginx
  - systemctl start nginx
```

Update `main.tf` to add the private interface to the web server:

```terraform
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

  interfaces {
    type = "public"
  }

  interfaces {
    type = "private"
    addresses {
      subnet_uuid = cloudscale_subnet.backend.id
      address     = "10.0.1.11"
    }
  }
}

resource "cloudscale_volume" "web_data" {
  name         = "${local.prefix}-web-data"
  zone_slug    = var.zone
  size_gb      = 50
  type         = "ssd"
  server_uuids = [cloudscale_server.web.id]
}
```

{{% alert title="Server replacement" color="secondary" %}}
Changing `user_data` always **forces replacement** of the server — Terraform destroys the
old one and creates a new one. This is expected and shown clearly in the execution plan as
`-/+` (destroy and create). The volume will be re-attached to the new server automatically
because its `server_uuids` references the resource ID.
{{% /alert %}}

Update `outputs.tf` to also show the backend's private address:

```terraform
output "web_public_ip" {
  description = "The public IPv4 address of the web server."
  value       = cloudscale_server.web.public_ipv4_address
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

The plan will show:

* `-/+` for `cloudscale_server.web` (replace due to `user_data` change)
* `+` for `cloudscale_network.backend`, `cloudscale_subnet.backend`, `cloudscale_server.backend`
* `~` for `cloudscale_volume.web_data` (re-attached to new server UUID)

Confirm with `yes`.


## Step {{% param sectionnumber %}}.6: Verify the Two-Tier Setup

After cloud-init completes on both servers (≈ 90 seconds), test the web server:

```bash
curl http://$(terraform output -raw web_public_ip)
```

Expected output:

```text
<html><body><h1>AlpDeploy</h1><p><b>Hostname:</b> alpdeploy-jane-web</p><p><b>Zone:</b> lpg1</p><p><b>Backend:</b> alpdeploy-jane-backend</p></body></html>
```

The `Backend:` field confirms the web server successfully reached the backend API via the
private network.

Verify that the backend is **not** reachable directly from the internet (the connection
should time out after a few seconds):

```bash
curl --connect-timeout 5 http://$(terraform output -raw backend_private_ip):8080 || echo "not reachable (expected)"
```

{{% details title="Hints" %}}
If the `Backend:` field shows `?`, the backend server may still be starting. The web
server cloud-init retries the backend call up to 10 times with a 3-second delay. If it
fails all retries, the page still loads — just with an unknown backend name.

You can regenerate the page at any time by SSHing in and re-running the Python command:

```bash
ssh debian@$(terraform output -raw web_public_ip)
curl -sf http://10.0.1.10:8080 -o /tmp/backend.json
python3 -c "import json; d=json.load(open('/tmp/meta.json')); b=json.load(open('/tmp/backend.json')); open('/var/www/html/index.html','w').write('<html><body><h1>AlpDeploy</h1><p><b>Hostname:</b> '+d.get('hostname','?')+'</p><p><b>Zone:</b> '+d.get('availability_zone','?')+'</p><p><b>Backend:</b> '+b.get('host','?')+'</p></body></html>\n')"
```

{{% /details %}}
