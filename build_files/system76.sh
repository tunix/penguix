#!/bin/bash

set -ouex pipefail

if [[ "$HARDWARE" != *"system76"* ]]; then
    echo "Skipping system76 related configuration..."
    exit 0
fi

echo "Installing system76 packages..."

dnf -y copr enable szydell/system76

dnf install -y \
    system76-firmware \
    firmware-manager \
    system76-driver \
    system76-keyboard-configurator \
    system76-power

# Disable tuned & tuned-ppd
systemctl mask tuned.service
systemctl mask tuned-ppd.service

# Enable system76 services
systemctl enable com.system76.PowerDaemon.service system76-power-wake system76-firmware-daemon
