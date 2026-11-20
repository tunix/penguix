# vim: set ft=just :
# Software installs. `brew bundle` (no upgrade flag) installs missing
# declarations only; upgrades are left to `brew upgrade` timers.


# Sync repo Brewfiles into the ublue convention path (~/.config/homebrew/)
# and install everything declared in them.
[group('Apps')]
penguix-brew:
    #!/usr/bin/env bash
    set -euo pipefail
    src="{{repo_root}}/brew"
    dest="$HOME/.config/homebrew"
    mkdir -p "$dest"
    for f in "$src"/*.Brewfile; do
        install -m 644 "$f" "$dest/"
        echo "Synced $(basename "$f") -> $dest/"
    done
    just penguix-brew-all

# Run brew bundle over every Brewfile (install missing, never upgrade).
[group('Apps')]
penguix-brew-all:
    #!/usr/bin/env bash
    set -euo pipefail
    for f in {{repo_root}}/brew/*.Brewfile; do
        echo "==> brew bundle: $(basename "$f")"
        brew bundle --file="$f"
    done

# Validate Brewfiles without evaluating them as Ruby (see script header).
[group('Apps')]
penguix-brew-check:
    #!/usr/bin/env bash
    set -euo pipefail
    bash "{{repo_root}}/scripts/validate-brewfiles.sh" "{{repo_root}}/brew"

# Brewfile categories, installable separately:
[group('Apps')]
penguix-brew-cli:
    brew bundle --file={{repo_root}}/brew/cli.Brewfile

[group('Apps')]
penguix-brew-coding:
    brew bundle --file={{repo_root}}/brew/coding.Brewfile

[group('Apps')]
penguix-brew-devops:
    brew bundle --file={{repo_root}}/brew/devops.Brewfile

[group('Apps')]
penguix-brew-gui:
    brew bundle --file={{repo_root}}/brew/apps.Brewfile

# Flatpaks declared via the brew bundle flatpak DSL (upstream Homebrew
# Bundle since 2025-12; see projectbluefin/documentation blog post).
[group('Apps')]
penguix-flatpaks:
    #!/usr/bin/env bash
    set -euo pipefail
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    brew bundle --file={{repo_root}}/brew/flatpak.Brewfile

# Install JetBrains Toolbox (user-level, no layering).
[group('Apps')]
install-jetbrains-toolbox:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing JetBrains Toolbox..."
    pushd "$(mktemp -d)"
    curl -sSfL -o releases.json "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
    BUILD_VERSION=$(jq -r '.TBA[0].build' ./releases.json)
    DOWNLOAD_LINK=$(jq -r '.TBA[0].downloads.linux.link' ./releases.json)
    CHECKSUM_LINK=$(jq -r '.TBA[0].downloads.linux.checksumLink' ./releases.json)
    echo "Installing JetBrains Toolbox ${BUILD_VERSION}"
    curl -sSfL -O "${DOWNLOAD_LINK}"
    curl -sSfL "${CHECKSUM_LINK}" | sha256sum -c
    tar zxf jetbrains-toolbox-"${BUILD_VERSION}".tar.gz
    mkdir -p "$HOME/.local/share/JetBrains/ToolboxApp/"
    mv jetbrains-toolbox-"${BUILD_VERSION}"/* "$HOME/.local/share/JetBrains/ToolboxApp/"
    popd
    "$HOME/.local/share/JetBrains/ToolboxApp/bin/jetbrains-toolbox" &
