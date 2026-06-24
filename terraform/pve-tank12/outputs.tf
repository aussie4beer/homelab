output "proxmox_node" {
  description = "Proxmox node name"
  value       = var.proxmox_node
}

output "vmbr0_address" {
  description = "vmbr0 IP address"
  value       = proxmox_network_linux_bridge.vmbr0.address
}

output "bond0_mode" {
  description = "Bond mode for bond0"
  value       = proxmox_network_linux_bond.bond0.bond_mode
}

output "storage_pools" {
  description = "Configured storage pool IDs"
  value = [
    proxmox_storage_directory.local.id,
    proxmox_storage_zfspool.local_zfs.id,
    proxmox_storage_zfspool.nvme_fast2.id,
  ]
}
