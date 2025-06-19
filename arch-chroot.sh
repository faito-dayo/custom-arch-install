#!/bin/bash

# Host info
echo -n "Enter timezone: "
read zoneinfo

echo -n "Enter host name: "
read hostname

echo -n "Enter username: "
read username

echo -n "Enter password for user: "
read -s password

echo -n "Enter root password: "
read -s rootpassword

# Set lang utf8 US
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
export LANG=en_US.UTF-8

# Set timezone
ln -s /usr/share/zoneinfo/$zoneinfo /etc/localtime
hwclock --systohc

# Set hostname
echo "$hostname" >> /etc/hostname

# Enable trim support
systemctl enable fstrim.timer

# Enable multilib
sed -zi 's/#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sed -i 's/\#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/' /etc/pacman.conf

# Update the repositories for the 32bit packages
sudo pacman -Sy

# Set root password
echo "root:${rootpassword}" | chpasswd

# Make a user acc
useradd -m -g users -G wheel,storage,power -s /bin/bash ${username}
echo "${username}:${password}" | chpasswd

# Visudo edit
cp /etc/sudoers /etc/sudoers.bak # Backup sudoers file just in case
sed -i 's/^#%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo "Defaults rootpw" >> /etc/sudoers

# Install the bootloader
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
bootctl install

# Write the boot entry
touch /boot/loader/entries/arch.conf
echo "title Arch" >> /boot/loader/entries/arch.conf
echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch.conf
echo "initrd /initramfs-linux.img" >> /boot/loader/entries/arch.conf

# Link drives
echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/vda3) rw" >> /boot/loader/entries/arch.conf

# Setup network
sudo pacman --noconfirm -Sy dhcpcd linux-headers
sudo systemctl enable dhcpcd@enp1s0.service

sudo pacman --noconfirm -Sy networkmanager
sudo systemctl enable NetworkManager.service

# Setup nvidia stuff
sudo pacman --noconfirm -Sy nvidia-dkms libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings
sed -zi 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
sed -zi '$ s/$/ nvidia-drm.modeset=1/' /boot/loader/entries/Arch.conf

# Setup pacman hooks
sudo mkdir /etc/pacman.d/hooks
touch /etc/pacman.d/hooks/nvidia.hook
hooksFile=/etc/pacman.d/hooks/nvidia.hook

echo "[Trigger]" >> ${hooksFile}
echo "Operation=Install" >> ${hooksFile}
echo "Operation=Upgrade" >> ${hooksFile}
echo "Operation=Remove" >> ${hooksFile}
echo "Type=Package" >> ${hooksFile}
echo "Target=nvidia" >> ${hooksFile}

echo "[Action]" >> ${hooksFile}
echo "Depends=mkinitcpio" >> ${hooksFile}
echo "When=PostTransaction" >> ${hooksFile}
echo "Exec=/usr/bin/mkinicpio -P" >> ${hooksFile}

# Let's install our other stuff now
sudo pacman --noconfirm -S niri sddm vlc nemo kleopatra bitwarden wofi kitty firefox
sudo systemctl enable sddm.service

# Now we exit
exit
