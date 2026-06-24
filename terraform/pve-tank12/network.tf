# Physical layout:
#   nic4 (enp136s0f0, 90:e2:ba:cb:ac:34) — 10GbE, active uplink
#   nic5 (enp136s0f1, 90:e2:ba:cb:ac:35) — 10GbE, failover partner
#   nic0–nic3 (331i onboard)              — 1GbE, available for mgmt/future use

resource "proxmox_virtual_environment_network_linux_bond" "bond0" {
  node_name = var.proxmox_node

  name    = "bond0"
  mode    = "active-backup"
  slaves  = ["nic4", "nic5"]
  primary = "nic4"
  mii_mon = 100

  comment = "10GbE active-backup bond (enp136s0f0 + enp136s0f1)"
}

resource "proxmox_virtual_environment_network_linux_bridge" "vmbr0" {
  node_name = var.proxmox_node

  name         = "vmbr0"
  address      = var.host_ip
  gateway      = var.host_gateway
  bridge_ports = ["bond0"]
  vlan_aware   = true
  bridge_stp   = false
  bridge_fd    = 0

  comment = "Main bridge — VLAN-aware, bond0 uplink"

  depends_on = [proxmox_virtual_environment_network_linux_bond.bond0]
}
