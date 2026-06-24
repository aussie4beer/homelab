# storage.tf -- pve-tank12 storage configuration

resource "proxmox_storage_directory" "local" {
  id      = "local"
  path    = "/var/lib/vz"
  content = ["iso", "vztmpl", "backup", "snippets"]
}

resource "proxmox_storage_zfspool" "local_zfs" {
  id             = "local-zfs"
  zfs_pool       = "rpool/data"
  nodes          = [var.proxmox_node]
  content        = ["images", "rootdir"]
  thin_provision = true
}

resource "proxmox_storage_zfspool" "nvme_fast2" {
  id       = "nvme-fast2"
  zfs_pool = "nvme-fast2"
  nodes    = [var.proxmox_node]
  content  = ["images", "rootdir"]
}
