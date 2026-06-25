# lxc-media-server.tf -- LXC 200 media-server
#
# Restored from vzdump backup taken on pve1 2026-06-25.
# Bind mounts are host paths -- not managed ZFS volumes.
# TUN device entries are written directly to /etc/pve/lxc/200.conf;
# the Proxmox API does not support lxc.* raw config params.

resource "proxmox_virtual_environment_container" "media_server" {
  node_name    = var.proxmox_node
  vm_id        = 200
  description  = "Media stack -- Jellyfin, Radarr, Sonarr, Prowlarr, qBittorrent, Gluetun"
  started      = false
  unprivileged = false

  cpu {
    cores = 4
  }

  memory {
    dedicated = 4096
    swap      = 512
  }

  operating_system {
    type             = "debian"
    template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  }

  disk {
    datastore_id = "nvme-fast2"
    size         = 16
  }

  # Bind mount -- WD drive imported as ZFS pool 'media', mounted at /media
  mount_point {
    volume = "/media"
    path   = "/mnt/media"
  }

  # Bind mount -- downloads dataset on nvme-fast2
  mount_point {
    volume = "/nvme-fast2/downloads"
    path   = "/mnt/downloads"
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "BC:24:11:90:F3:1D"
    firewall    = false
  }

  initialization {
    hostname = "media-server"
    ip_config {
      ipv4 {
        address = "192.168.1.188/24"
        gateway = "192.168.1.1"
      }
    }
    dns {
      servers = ["192.168.1.1"]
      domain  = "fosternet.home"
    }
  }

  features {
    nesting = true
  }

  lifecycle {
    ignore_changes = [
      operating_system,
      mount_point,
      initialization[0].hostname,
      console,
    ]
  }
}
