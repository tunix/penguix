# penguix

Custom OS image based on [Bluefin DX](https://projectbluefin.io).

> Be the one who moves, not the one who is moved.

## What Makes this Raptor Different?

Build-time: Ghostty, Solaar.

Runtime (`ujust penguix-install-all`):

- **CLI**: 1Password CLI, atuin, btop, direnv, httpie, lazygit, neovim, ripgrep, rtk, sd, ag, zellij
- **Coding**: golang, nvm, openjdk, rustup
- **Devops**: ansible, argocd, awscli, cosign, dive, helm, k9s, kafkactl, kind, kubectl, kubectx, lego, sshpass, terraform
- **GUI**: 1Password, Brave, Discord, Slack, Spotify, Telegram, Zoom, Obsidian, LibreOffice, GIMP, Proton VPN, Karere

Also: default TTL 65, masked wait-online/udev-settle services, GNOME dconf and autostart for 1Password and Solaar.

## What's Included

- GitHub Actions builds (`:stable-testing` from `main`, `:stable` from `stable`)
- Homebrew Brewfiles and `ujust` shortcuts
- Keyless image signing

## Installing penguix

Install [Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/) or [Bluefin](https://projectbluefin.io), then:

```bash
sudo bootc switch --transport registry ghcr.io/tunix/penguix:stable
sudo systemctl reboot
```

After reboot:

```bash
ujust penguix-install-all
```

Testing stream: `ghcr.io/tunix/penguix:stable-testing`. Rollback with `sudo bootc rollback`.
