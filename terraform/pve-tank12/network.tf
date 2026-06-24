# network.tf -- pve-tank12 network configuration
#
# Physical layout:
#   nic4 (enp136s0f0, 90:e2:ba:cb:ac:34) -- 10GbE, active uplink
#   nic5 (enp136s0f1, 90:e2:ba:cb:ac:35) -- 10GbE, failover partner
#   nic0-nic3 (331i onboard)              -- 1GbE, available for future use

resource "proxmox_network_linux_bond" "bond0" {
  node_name    = var.proxmox_node
  name         = "bond0"
  slaves       = ["nic4", "nic5"]
  bond_mode    = "active-backup"
  bond_primary = "nic4"
  comment      = "10GbE active-backup bond (enp136s0f0 + enp136s0f1)"
}

resource "proxmox_network_linux_bridge" "vmbr0" {
  node_name  = var.proxmox_node
  name       = "vmbr0"
  address    = var.host_ip
  gateway    = var.host_gateway
  ports      = ["bond0"]
  vlan_aware = true
  comment    = "Main bridge -- VLAN-aware, bond0 uplink"
  depends_on = [proxmox_network_linux_bond.bond0]
}
