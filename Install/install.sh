#!/bin/bash

# Passage en root
sudo -i

# GPT partition table
parted /dev/sda -- mklabel gpt

# /, swap and /boot
parted /dev/sda -- mkpart primary ext4 1MiB 512MiB
parted /dev/sda -- mkpart primary linux-swap 512MiB 1024MiB
parted /dev/sda -- mkpart primary ext4 1024MiB 100%

# Format partitions
mkfs.ext4 /dev/sda1
mkswap /dev/sda2
mkfs.ext4 /dev/sda3

# Mount partitions
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
swapon /dev/sda2

# Install NixOS
nixos-install --no-root-passwd --root /mnt

# Configure NixOS
cat <<EOF > /mnt/etc/nixos/configuration.nix
{ pkgs, ... }:

{
  imports = [ pkgs.nixos.options ];

  system.stateVersion = "25.05";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  fileSystems."/" = {
    device = "/dev/sda3";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/sda2"; } ];

  networking.hostName = "nixos";

  users.users.root.initialPassword = "password";
}
EOF

# Reboot
reboot
