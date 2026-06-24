# lxc-media-server.tf -- LXC 200 media-server migration target
#
# Source config from pve1 (pre-migration):
#   pct config 200 on pve1.fosternet.home
#
# Storage changes from pve1:
#   rootfs:    nvme-fast        -> nvme-fast2
#   downloads: /nvme-fast/downloads (bind) -> nvme-fast2 subvolume
#   media:     /media (bind, WD external)  -> /media (bind, WD in 12-bay bay)
#              pool absent until drive physically moved and imported:
#              zpool import media
#
# Network change from pve1:
#   ip=dhcp -> static 192.168.1.188/24 (existing Unifi reservation retained)

resource "proxmox_virtual_environment_container" "media_server" {
  node_name   = var.proxmox_node
  vm_id       = 200
  description = "Media stack -- Jellyfin, Radarr, Sonarr, Prowlarr, qBittorrent, Gluetun"

  started     = true
  unprivileged = false

  cpu {
    cores = 4
  }

  memory {
    dedicated = 4096
    swap      = 512
  }

  operating_system {
    type           = "debian"
    template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  }

  disk {
    datastore_id = "nvme-fast2"
    size         = 16
  }

  # Downloads subvolume on nvme-fast2
  mount_point {
    volume = "nvme-fast2"
    size   = "100G"
    path   = "/mnt/downloads"
  }

  # Media bind mount -- WD drive in 12-bay HDD slot
  # Pool must be imported first: zpool import media
  mount_point {
    volume = "/media"
    path   = "/mnt/media"
  }

  network_interface {
    name     = "eth0"
    bridge   = "vmbr0"
    mac_address = "BC:24:11:90:F3:1D"
    firewall = false
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.188/24"
        gateway = "192.168.1.1"
      }
    }
    dns {
      servers = ["192.168.1.1"]
      domain = "fosternet.home"
    }
  }

  features {
    nesting = true
  }

  # TUN device for Gluetun VPN -- required for ProtonVPN WireGuard
  # These are written via SSH as the Proxmox API does not support lxc[] params.
  # Manually verify /etc/pve/lxc/200.conf contains:
  #   lxc.cgroup2.devices.allow: c 10:200 rwm
  #   lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
}
