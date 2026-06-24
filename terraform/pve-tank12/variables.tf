variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
  default     = "https://192.168.1.12:8006/"
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the format user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve-tank12"
}

variable "host_ip" {
  description = "Proxmox host IP address with prefix length"
  type        = string
  default     = "192.168.1.12/24"
}

variable "host_gateway" {
  description = "Default gateway for the Proxmox host"
  type        = string
  default     = "192.168.1.1"
}

variable "vlan_ids" {
  description = "VLAN IDs intended for this host (informational)"
  type        = list(number)
  default     = []
}
