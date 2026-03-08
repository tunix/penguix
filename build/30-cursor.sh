#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

echo "::group:: Installing Cursor..."

# Add Cursor RPM repository GPG key
rpm --import https://downloads.cursor.com/keys/anysphere.asc

# Add Cursor RPM repository
cat > /etc/yum.repos.d/cursor.repo << 'EOF'
[cursor]
name=Cursor
baseurl=https://downloads.cursor.com/yumrepo
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.cursor.com/keys/anysphere.asc
EOF

# Install Cursor
dnf install -y cursor

# Clean up repo file (required - repos don't work at runtime in bootc images)
rm -f /etc/yum.repos.d/cursor.repo

echo "Cursor installed successfully"
echo "::endgroup::"