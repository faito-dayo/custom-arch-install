#!/bin/bash

echo "Shibuya Arch Linux Setup"

# Set up file system
mkfs.fat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3

# Mount
mount /dev/vda3 /mnt
mkdir /mnt/boot
mkdir /mnt/home
mount /dev/sda1 /mnt/boot
mount /dev/sdb1 /mnt/home

# Pacstrap
pacstrap -K /mnt base linux-firmware base-devel

# Generate an fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

# Chroot into installed system (copy mkinitcpio first)
cp arch-install/scripts/arch-chroot.sh /mnt
chmod +x /mnt/arch-chroot.sh
arch-chroot /mnt ./arch-chroot.sh

# We finished with setting up the system.
echo 'Done with chroot'

reboot -n