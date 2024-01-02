#!/bin/sh -e


# Partition disk
cat <<FDISK | fdisk /dev/sda
n




a
w

FDISK

# Create filesystem
mkfs.ext4 -j -L nixos /dev/sda1

# Mount filesystem
mount LABEL=nixos /mnt

# Setup system
nixos-generate-config --root /mnt

mkdir /mnt/etc/nixos/networking

# Get the files into the VM (may be a good idea to copy the directory ?)
curl -sf "$PACKER_HTTP_ADDR/nix/networking/default.nix" > /mnt/etc/nixos/networking/default.nix
curl -sf "$PACKER_HTTP_ADDR/nix/networking/hostname.nix" > /mnt/etc/nixos/networking/hostname.nix
curl -sf "$PACKER_HTTP_ADDR/nix/networking/network.nix" > /mnt/etc/nixos/networking/network.nix
curl -sf "$PACKER_HTTP_ADDR/nix/builders/$PACKER_BUILDER_TYPE.nix" > /mnt/etc/nixos/hardware-builder.nix
curl -sf "$PACKER_HTTP_ADDR/nix/configuration.nix" > /mnt/etc/nixos/configuration.nix

### Install ###
nixos-install

### Cleanup ###
curl "$PACKER_HTTP_ADDR/scripts/post_install.sh" | nixos-enter
