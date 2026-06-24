output "proxmox_node" {
  description = "Proxmox node name"
  value       = var.proxmox_node
}

output "vmbr0_address" {
  description = "vmbr0 IP address"
  value       = proxmox_virtual_environment_network_linux_bridge.vmbr0.address
}

output "bond0_mode" {
  description = "Bond mode for bond0"
  value       = proxmox_virtual_environment_network_linux_bond.bond0.mode
}

output "storage_pools" {
  description = "Configured storage pool IDs"
  value = [
    proxmox_virtual_environment_storage.local.storage_id,
    proxmox_virtual_environment_storage.local_zfs.storage_id,
    proxmox_virtual_environment_storage.nvme_fast2.storage_id,
  ]
}
