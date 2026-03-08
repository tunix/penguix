#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

echo "::group:: Installing Antigravity..."

# Add Antigravity RPM repository
cat > /etc/yum.repos.d/antigravity.repo << 'EOF'
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
EOF

# Install Antigravity
dnf install -y antigravity

# Clean up repo file (required - repos don't work at runtime in bootc images)
rm -f /etc/yum.repos.d/antigravity.repo

echo "Antigravity installed successfully"
echo "::endgroup::"
