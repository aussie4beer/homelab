# Terraform -- pve-tank12

Infrastructure-as-code for the `pve-tank12` Proxmox host (HPE DL380 Gen9,
`192.168.1.12`). Manages host-level network and storage configuration using
the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest)
provider.

## Scope

| File | Manages |
|---|---|
| `providers.tf` | Provider version, API auth, SSH agent |
| `network.tf` | `bond0` (active-backup), `vmbr0` (VLAN-aware bridge) |
| `storage.tf` | `local`, `local-zfs`, `nvme-fast2` storage pools |
| `lxc-media-server.tf` | LXC 200 media-server definition (migration target) |
| `variables.tf` | All input variable declarations |
| `outputs.tf` | Node name, bridge IP, bond mode, pool IDs |

## Prerequisites

1. Terraform >= 1.7.0 or OpenTofu >= 1.6.0
2. SSH agent running with root key loaded for pve-tank12:
```bash
   eval $(ssh-agent)
   ssh-add ~/.ssh/id_ed25519
```
3. API token created on pve-tank12 and saved to Bitwarden as
   `pve-tank12 Terraform token`.

## API token setup (one-time)

```bash
pveum user add terraform@pve --comment "Terraform service account"
pveum acl modify / --roles Administrator --users terraform@pve
pveum acl modify /nodes/pve-tank12 --roles Administrator --users terraform@pve
pveum user token add terraform@pve terraform --privsep 0
```

Token format for `terraform.tfvars`: `terraform@pve!terraform=<secret>`

### Role note

The `Administrator` role is used here because `PVEAdmin` lacks `Sys.Modify`,
which is required for network interface creation (bonds, bridge port changes).

For production environments, create a custom role with only the required
privileges instead of granting `Administrator`:

```bash
pveum role add TerraformAdmin --privs \
  "Datastore.Allocate,Datastore.AllocateSpace,Datastore.AllocateTemplate,\
Datastore.Audit,Sys.Audit,Sys.Console,Sys.Modify,Sys.Syslog,\
VM.Allocate,VM.Audit,VM.Backup,VM.Clone,VM.Config.CDROM,VM.Config.CPU,\
VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,\
VM.Config.Network,VM.Config.Options,VM.Console,VM.Migrate,VM.Monitor,\
VM.PowerMgmt,VM.Replicate,VM.Snapshot,VM.Snapshot.Rollback,\
Pool.Allocate,Pool.Audit,SDN.Allocate,SDN.Audit,SDN.Use"
```

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with real values

terraform init
terraform plan
terraform apply
```

## Network layout
nic4 (10GbE, enp136s0f0) --+

+-- bond0 (active-backup) -- vmbr0 (VLAN-aware)

nic5 (10GbE, enp136s0f1) --+                               |

192.168.1.12/24
nic0-nic3 (1GbE onboard, 331i) -- unconfigured, available for mgmt/future use

`vmbr0` is VLAN-aware. Assign VLAN tags at the VM/LXC NIC level.
Populate `vlan_ids` in `terraform.tfvars` when VLANs are defined in Unifi.

### Bond creation note

The bpg/proxmox provider cannot create a bond while `nic4` is in use as a
bridge port. If rebuilding from scratch, use this sequence:

```bash
# 1. Remove nic4 from vmbr0
pvesh set /nodes/pve-tank12/network/vmbr0 --type bridge --bridge_ports ""

# 2. Create bond0 manually
pvesh create /nodes/pve-tank12/network \
  --type bond --iface bond0 --slaves "nic4 nic5" \
  --bond_mode active-backup --bond-primary nic4

# 3. Reattach vmbr0 to bond0
pvesh set /nodes/pve-tank12/network/vmbr0 \
  --type bridge --bridge_ports bond0 --bridge_vlan_aware 1

# 4. Apply network config
pvesh set /nodes/pve-tank12/network

# 5. Import into Terraform state
terraform import proxmox_network_linux_bond.bond0 pve-tank12:bond0
terraform import proxmox_network_linux_bridge.vmbr0 pve-tank12:vmbr0
```

## Storage layout

| ID | Type | Pool | Size | Use |
|---|---|---|---|---|
| `local` | dir | `/var/lib/vz` | 237GB | ISOs, templates, backups |
| `local-zfs` | zfspool | `rpool/data` | 237GB | OS NVMe -- VM/LXC disks |
| `nvme-fast2` | zfspool | `nvme-fast2` | 5.81TB | Primary workload pool |

12x 3.5" HDD bays are currently empty. A large-capacity ZFS pool for
media/archive will be added to `storage.tf` when drives are populated.

## LXC 200 -- media-server

Migration target from `pve1`. The container definition is in
`lxc-media-server.tf`. Before migrating:

1. Physically move WD media drive to a 12-bay HDD slot on pve-tank12
2. Import the ZFS pool: `zpool import media`
3. `vzdump` LXC 200 on pve1 and restore to pve-tank12
4. Run `terraform import proxmox_virtual_environment_container.media_server 200`
5. Run `terraform plan` -- should show only the TUN device note as drift

The TUN device entries (`lxc.cgroup2.devices.allow` and `lxc.mount.entry`)
cannot be managed via the Proxmox API. Add them manually after restore:

```bash
echo 'lxc.cgroup2.devices.allow: c 10:200 rwm' >> /etc/pve/lxc/200.conf
echo 'lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file' >> /etc/pve/lxc/200.conf
```
