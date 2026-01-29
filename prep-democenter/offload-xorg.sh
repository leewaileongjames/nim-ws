#!/bin/bash

set -e

echo "Creating /etc/X11/xorg.conf..."
sudo tee /etc/X11/xorg.conf > /dev/null <<EOF
Section "Device"
    Identifier      "intel"
    Driver          "intel"
    BusId           "PCI:0:f:0"
EndSection

Section "Screen"
    Identifier      "intel"
    Device          "intel"
EndSection
EOF

echo "Updating GRUB to add 'nogpumanager' parameter..."

GRUB_FILE="/etc/default/grub"

# Only add parameter if missing
if grep -q "nogpumanager" "$GRUB_FILE"; then
    echo "'nogpumanager' already present in GRUB options."
else
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nogpumanager /' "$GRUB_FILE"
    echo "Added 'nogpumanager' to GRUB_CMDLINE_LINUX_DEFAULT."
fi

echo "Running update-grub..."
sudo update-grub

echo "Rebooting system in 5 seconds... Press CTRL+C to cancel."
sleep 5
sudo reboot