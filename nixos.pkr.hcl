packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

locals {
    iso_url = "https://channels.nixos.org/nixos-${var.version}/latest-nixos-minimal-${var.arch}-linux.iso"
}

variable "builder" {
  description = "builder"
  type = string
  default = "qemu"
}

variable "version" {
  description = "The version of NixOS to build"
  type = string
  default = "23.11"
}

variable "arch" {
  description = "The system architecture of NixOS to build (Default: x86_64)"
  type = string
  default = "x86_64"
}

variable "iso_checksum" {
  description = "A ISO SHA256 value"
  type = string
  default = "a14c853cf4707e6bc9fe24153b665ca1e370d7e47d9e09344be586ab027cb79f"
}

variable "disk_size" {
  type    = string
  default = "3072M"
}

variable "memory" {
  type    = string
  default = "5120M"
}

variable "boot_wait" {
  description = "The amount of time to wait for VM boot"
  type = string
  default = "60s"
}

source "qemu" "nixos_image" {
  boot_command         = [
    "mkdir -m 0700 .ssh<enter>",
    "curl http://{{ .HTTPIP }}:{{ .HTTPPort }}/config/ssh_public_key.pub > .ssh/authorized_keys<enter>",
    "sudo systemctl start sshd<enter>"
  ]
  boot_wait            = var.boot_wait
  disk_interface       = "virtio-scsi"
  disk_size            = var.disk_size
  format               = "raw"
  headless             = true
  http_directory       = "files"
  iso_checksum         = var.iso_checksum
  iso_url              = local.iso_url
  qemuargs             = [["-m", var.memory], ["-smp", "12"]]
  shutdown_command     = "sudo shutdown -h now"
  ssh_port             = 22
  ssh_private_key_file = "./files/config/ssh_private_key"
  ssh_username         = "nixos"
  vm_name              = "disk.raw"
}

build {
  sources = [
    "source.qemu.nixos_image",
  ]

  provisioner "file" {
    destination = "/tmp/"
    source      = "./files/"
  }

  provisioner "shell" {
    execute_command = "sudo su -c '{{ .Vars }} {{ .Path }}'"
    script          = "./files/scripts/install.sh"
  }
}
