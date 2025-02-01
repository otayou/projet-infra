############################################################
# 1) Terraform + Libvirt Providers
############################################################
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.7.0"
    }
  }
  required_version = ">= 1.0"
}

# HOST1: local KVM
provider "libvirt" {
  uri   = "qemu:///system"
}



resource "libvirt_volume" "ubuntu_cloud_host1" {
  count    = 3
  name     = "ubuntu-host1-vm-${count.index + 1}.img"
  pool     = "default"
  source   = "/home/noussairelassali/images/ubuntu.img"
  format   = "qcow2"
}


############################################################
# 3) Cloud-Init Config
############################################################
resource "libvirt_cloudinit_disk" "host1_cloudinit" {
  count          = 3
  name           = "ubuntu-host1-cloudinit-${count.index + 1}.iso"
  pool           = "default"
  user_data      = file("${path.module}/files/cloud_init.cfg")
  network_config = file("${path.module}/files/${lookup(
    { 0 = "network_config_master.cfg", 1 = "network_config_worker1.cfg", 2 = "network_config_worker2.cfg" },
    count.index,
    "default.cfg"
  )}")
}


############################################################
# 4) Create the VMs
############################################################

# Host1: Create 3 VMs (1 master and 2 workers)
resource "libvirt_domain" "host1_vms" {
  count    = 3
  name     = "host1-vm-${count.index + 1}"
  memory   = 2048
  vcpu     = 2

  # Attach the Ubuntu volume (Host1)
  disk {
    volume_id = libvirt_volume.ubuntu_cloud_host1[count.index].id
  }

  # Attach cloud-init ISO (Host1)
  cloudinit = libvirt_cloudinit_disk.host1_cloudinit[count.index].id

  network_interface {
    network_name = "default"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

