---
title: "10.2. Persistent Storage"
weight: 102
sectionnumber: 10.2
onlyWhen: cloudscale
---


## Preparation

Continue in the same working directory from the previous lab:

```bash
cd $LAB_ROOT/cloudscale
```


## Step {{% param sectionnumber %}}.1: Add a Block Volume

The AlpDeploy web service needs persistent storage that survives server re-creates — for
example for uploaded files or a local cache. cloudscale.ch provides SSD and bulk block
volumes that can be attached to servers.

Add the `"cloudscale_volume" "web_data"` resource to `main.tf`:

```terraform
resource "cloudscale_volume" "web_data" {
  name         = "${local.prefix}-web-data"
  zone_slug    = var.zone
  size_gb      = 50
  type         = "ssd"
  server_uuids = [cloudscale_server.web.id]
}
```


### Explanation

The `cloudscale_volume` resource creates a block storage volume and attaches it to the
server by listing the server's UUID in `server_uuids`.

| Argument | Value | Notes |
| --- | --- | --- |
| `size_gb` | `50` | Volume size — can be increased later |
| `type` | `"ssd"` | `"ssd"` for NVMe-backed storage, `"bulk"` for capacity-optimised HDD |
| `server_uuids` | list | Volumes support multi-attach (multiple servers) |

Because `server_uuids` references `cloudscale_server.web.id`, Terraform automatically
creates the server first and attaches the volume afterwards. This **implicit dependency**
is a core Terraform feature — you rarely need explicit `depends_on`.


## Step {{% param sectionnumber %}}.2: Apply the Change

```bash
terraform apply
```

Terraform shows one new resource to add (`cloudscale_volume.web_data`) and no changes to
the existing server.

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

Confirm with `yes`.


## Step {{% param sectionnumber %}}.3: Verify and Prepare the Volume

SSH into the server:

```bash
ssh debian@$(terraform output -raw web_public_ip)
```

Confirm the volume is visible as a second block device:

```bash
lsblk
```

Expected output (the root disk is `/dev/vda`, the new volume is `/dev/vdb`):

```text
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
vda    252:0    0   10G  0 disk
├─vda1 252:1    0    9G  0 part /
├─vda2 252:2    0    1K  0 part
└─vda5 252:5    0  975M  0 part [SWAP]
vdb    252:16   0   50G  0 disk
```

Format the volume with ext4 (only needed on first use):

```bash
sudo mkfs.ext4 /dev/vdb
```

Create a mount point and mount the volume:

```bash
sudo mkdir -p /data
sudo mount /dev/vdb /data
df -h /data
```

Expected output:

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/vdb         49G   24K   47G   1% /data
```


## Step {{% param sectionnumber %}}.4: Make the Mount Permanent

Add the volume to `/etc/fstab` so it is automatically mounted after a reboot:

```bash
echo '/dev/vdb /data ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

Verify the entry is correct:

```bash
sudo mount -a
df -h /data
```

Exit the SSH session:

```bash
exit
```


### Explanation

{{% alert title="Terraform vs. configuration management" color="secondary" %}}
Terraform is responsible for **infrastructure**: creating the volume and attaching it to
the server. Formatting the filesystem and mounting it are **OS-level operations** that fall
outside Terraform's scope. In production, tools like Ansible, cloud-init, or a
configuration management system handle these steps.

In a real project you would encode the `mkfs` and `fstab` steps in the cloud-init
`user_data` (or a separate provisioner), but for learning purposes running them manually
makes the boundary between infrastructure and configuration management clear.
{{% /alert %}}
