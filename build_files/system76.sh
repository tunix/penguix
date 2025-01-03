#!/bin/bash

set -ouex pipefail

echo "Installing system76 packages..."

# Setup repo
cat << EOF > /etc/yum.repos.d/system76.repo
[copr:copr.fedorainfracloud.org:szydell:system76]
name=Copr repo for system76 owned by szydell
baseurl=https://download.copr.fedorainfracloud.org/results/szydell/system76/fedora-\$releasever-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/szydell/system76/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF

# Import signing key
rpm --import https://download.copr.fedorainfracloud.org/results/szydell/system76/pubkey.gpg

dnf5 install -y \
    system76-firmware \
    firmware-manager \
    system76-driver \
    system76-keyboard-configurator \
    system76-power

# Clean up the yum repo (updates are baked into new images)
rm /etc/yum.repos.d/system76.repo -f

# Disable tuned & tuned-ppd
systemctl mask tuned.service
systemctl mask tuned-ppd.service

# Enable system76 services
systemctl enable com.system76.PowerDaemon.service system76-power-wake system76-firmware-daemon
