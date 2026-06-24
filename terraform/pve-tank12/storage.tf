# Pools as confirmed by pvesm status.
# 12x 3.5" HDD bays are empty — media/archive pool to be added when populated.

resource "proxmox_virtual_environment_storage" "local" {
  node_name  = var.proxmox_node
  storage_id = "local"
  type       = "dir"
  path       = "/var/lib/vz"

  content {
    iso_image          = true
    container_template = true
    backup             = true
    snippets           = true
  }

  comment = "Local directory storage — ISOs, templates, backups"
}

resource "proxmox_virtual_environment_storage" "local_zfs" {
  node_name  = var.proxmox_node
  storage_id = "local-zfs"
  type       = "zfspool"
  pool       = "rpool/data"

  content {
    disk_image = true
    container  = true
    rootdir    = true
  }

  comment = "OS NVMe ZFS pool (256GB) — rpool"
}

resource "proxmox_virtual_environment_storage" "nvme_fast2" {
  node_name  = var.proxmox_node
  storage_id = "nvme-fast2"
  type       = "zfspool"
  pool       = "nvme-fast2"

  content {
    disk_image = true
    container  = true
    rootdir    = true
  }

  comment = "Primary workload ZFS pool — 5.81TB stripe (2x 3.2TB NVMe PCIe)"
}
