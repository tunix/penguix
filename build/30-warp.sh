#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

echo "::group:: Installing Warp Terminal..."

# Official install for RHEL-, Fedora-, and CentOS-based systems:
# https://docs.warp.dev/getting-started/quickstart/installation-and-setup/
rpm --import https://releases.warp.dev/linux/keys/warp.asc

cat > /etc/yum.repos.d/warpdotdev.repo << 'EOF'
[warpdotdev]
name=warpdotdev
baseurl=https://releases.warp.dev/linux/rpm/stable
enabled=1
gpgcheck=1
gpgkey=https://releases.warp.dev/linux/keys/warp.asc
EOF

dnf5 install -y warp-terminal

# Remove repo file (bootc image pattern; matches other third-party RPM scripts in this repo)
rm -f /etc/yum.repos.d/warpdotdev.repo

echo "Warp Terminal installed successfully (run: warp-terminal)"
echo "::endgroup::"
