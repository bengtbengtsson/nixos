#!/bin/bash

# Exit on any error
set -e

# Load Swedish keyboard layout and set terminal font
# sudo loadkeys sv-latin1
# sudo setfont ter-v32n

# Set the root password
# echo "Setting root password..."
# passwd root

# Start wpa_supplicant to configure WiFi
# echo "Starting wpa_supplicant service..."
# systemctl start wpa_supplicant

# Pause for user input to configure WiFi using wpa_cli
#echo "Now configuring WiFi with wpa_cli..."
# wpa_cli <<EOF
# add_network
# set_network 0 ssid "Bengtsson"
# set_network 0 psk "<password>"  # Replace <password> with your WiFi password
# enable_network 0
# save_config
# quit
# EOF

# Verify internet connection
echo "Pinging google.com to verify network connection..."
ping -c 3 google.com

# Create and format partitions
echo "Creating and formatting partitions..."
parted --script /dev/nvme0n1 mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MB 512MB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 512MB 100%
parted /dev/nvme0n1 name 2 cryptic

# Format the boot partition
echo "Formatting boot partition..."
mkfs.fat -F 32 -n boot /dev/nvme0n1p1

# Set up LUKS encryption on the root partition
echo "Setting up LUKS encryption on /dev/nvme0n1p2..."
cryptsetup luksFormat /dev/nvme0n1p2 --batch-mode

# Open the encrypted LUKS partition
echo "Opening encrypted LUKS partition..."
cryptsetup open /dev/nvme0n1p2 cryptroot

# Format the decrypted LUKS partition as ext4
echo "Formatting root partition as ext4..."
mkfs.ext4 -L nixos /dev/mapper/cryptroot

# Mount the file systems
echo "Mounting root and boot file systems..."
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot
mount -o umask=0077 /dev/nvme0n1p1 /mnt/boot

# Generate the initial NixOS configuration
echo "Generating NixOS configuration..."
nixos-generate-config --root /mnt

# Replace the configuration files with those from your GitHub repository
echo "Cloning configuration files from GitHub..."
curl -L https://raw.githubusercontent.com/bengtbengtsson/nixos/main/configuration.nix -o /mnt/etc/nixos/configuration.nix
curl -L https://raw.githubusercontent.com/bengtbengtsson/nixos/main/hardware-configuration.nix -o /mnt/etc/nixos/hardware-configuration.nix

# Install NixOS
echo "Installing NixOS..."
nixos-install

# Set password to user ben
passwd ben

# Create .xinitrc for ben
echo "exec dwm" >> /mnt/home/ben/.xinitrc

# Done!
echo "Installation complete. Check your system and then reboot"
# Reboot the system
#echo "Installation complete. Rebooting system..."
#reboot
