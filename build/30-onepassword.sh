#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

### Install 1Password from Official Repository
echo "::group:: Installing 1Password..."

# Add 1Password RPM repository GPG key
rpm --import https://downloads.1password.com/linux/keys/1password.asc

# Add 1Password RPM repository
cat > /etc/yum.repos.d/1password.repo << 'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

# Install 1Password
dnf5 install -y 1password 1password-cli

# Clean up repo file (required - repos don't work at runtime in bootc images)
rm -f /etc/yum.repos.d/1password.repo

echo "1Password installed successfully"
echo "::endgroup::"