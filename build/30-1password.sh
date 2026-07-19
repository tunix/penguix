#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

### Fix 1Password CLI permissions automatically after Homebrew upgrades
echo "::group:: Installing 1Password CLI permission fixer..."

# Homebrew resets ownership/permissions of the op binary on every upgrade,
# which breaks the 1Password desktop app integration. A path unit watches
# the Caskroom and re-applies root:onepassword-cli + setgid automatically.
# https://github.com/ublue-os/homebrew-tap/issues/208

# script executed by the systemd service
install -Dm0755 /ctx/custom/1password/bin/onepassword-cli-perms /usr/libexec/onepassword-cli-perms

# systemd path + service units
cp /ctx/custom/1password/systemd/onepassword-cli-perms.path /usr/lib/systemd/system/
cp /ctx/custom/1password/systemd/onepassword-cli-perms.service /usr/lib/systemd/system/

# create the onepassword-cli group at boot
install -Dm0644 /ctx/custom/1password/sysusers.d/onepassword-cli.conf /usr/lib/sysusers.d/onepassword-cli.conf

systemctl enable onepassword-cli-perms.path

echo "1Password CLI permission fixer installed successfully"
echo "::endgroup::"
