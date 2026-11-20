# vim: set ft=just :
# System-adjacent recipes. Everything here is per-user except the single
# opt-in sysctl tweak, which cannot exist at user level (sysctls are
# kernel-global) and is therefore gated behind an explicit confirmation.

# Change login shell for the current user.
[group('System')]
change-shell shell='/usr/bin/fish':
    #!/usr/bin/env bash
    sudo usermod --shell {{shell}} "$(id -un)"

alias chsh := change-shell

# Update the OS (bootc) and offer a reboot.
[group('System')]
update-and-reboot:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Updating system..."
    sudo bootc upgrade
    if gum confirm "Reboot now to apply updates?"; then
        systemctl reboot
    else
        echo "Update staged; apply on next reboot."
    fi

# Clean up podman images/containers/volumes.
[group('Maintenance')]
clean-containers:
    #!/usr/bin/env bash
    echo "Cleaning up Podman containers, images, and volumes..."
    podman system prune -af
    podman volume prune -f
    echo "Cleanup complete!"

# OPTIONAL, opt-in: anti-fingerprinting default TTL. This is the only
# recipe in this repo that writes outside $HOME (it needs root because
# sysctls are kernel-global; there is no userspace sysctl).
[group('System')]
penguix-sysctl-ttl:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! gum confirm "Write net.ipv4.ip_default_ttl=65 to /etc/sysctl.d/99-penguix-ttl.conf? (sudo)"; then
        exit 0
    fi
    printf 'net.ipv4.ip_default_ttl=65\n' | sudo tee /etc/sysctl.d/99-penguix-ttl.conf >/dev/null
    sudo sysctl --system
    echo "TTL applied. Reversal: sudo rm /etc/sysctl.d/99-penguix-ttl.conf && sudo sysctl --system"
