#!/bin/bash
set -euo pipefail

echo "Creating /etc/X11/xorg.conf..."
sudo tee /etc/X11/xorg.conf > /dev/null <<'EOF'
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

GRUB_FILE="/etc/default/grub"

echo "Updating GRUB to place 'nogpumanager' after 'quiet splash'..."

# 1) If already present, do nothing
if grep -qE 'GRUB_CMDLINE_LINUX_DEFAULT=.*\bnogpumanager\b' "$GRUB_FILE"; then
  echo "'nogpumanager' already present in GRUB_CMDLINE_LINUX_DEFAULT."
else
  # 2) If 'quiet splash' exists, insert immediately after it (inside the same quotes)
  if grep -qE 'GRUB_CMDLINE_LINUX_DEFAULT="[^"]*quiet splash([^"]*)"' "$GRUB_FILE"; then
    sudo sed -i \
      's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*quiet splash\)\([^"]*"\)/\1 nogpumanager\2/' \
      "$GRUB_FILE"
    echo "Inserted 'nogpumanager' after 'quiet splash'."
  else
    # 3) Otherwise, append at end of the quoted value
    sudo sed -i \
      's/^\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 nogpumanager"/' \
      "$GRUB_FILE"
    echo "Appended 'nogpumanager' to GRUB_CMDLINE_LINUX_DEFAULT."
  fi
fi

echo "Running update-grub..."
sudo update-grub

echo "Rebooting system in 5 seconds... Press CTRL+C to cancel."
sleep 5
sudo reboot