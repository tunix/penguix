# vim: set ft=just :
#######################
### penguix-apps.just
#######################

# Install all applications for penguix at once
[group('Apps')]
penguix-install-all:
    #!/usr/bin/env bash
    echo "Installing applications for penguix..."
    
    brew bundle upgrade --file /usr/share/ublue-os/homebrew/penguix-cli.Brewfile
    brew bundle upgrade --file /usr/share/ublue-os/homebrew/penguix-coding.Brewfile
    brew bundle upgrade --file /usr/share/ublue-os/homebrew/penguix-devops.Brewfile
    brew bundle upgrade --file /usr/share/ublue-os/homebrew/penguix-flatpak.Brewfile

# Install cli applications for penguix
[group('Apps')]
penguix-install-cli:
    #!/usr/bin/env bash
    echo "Installing CLI applications for penguix..."
    
    brew bundle upgrade --file /usr/share/ublue-os/homebrew/penguix-cli.Brewfile

# Install coding applications for penguix
[group('Apps')]
penguix-install-coding:
    #!/usr/bin/env bash
    echo "Installing coding applications for penguix..."
    
    brew bundle upgrade --file /usr/share/ublue-os/homebrew/penguix-coding.Brewfile

# Install devops applications for penguix
[group('Apps')]
penguix-install-devops:
    #!/usr/bin/env bash
    echo "Installing devops applications for penguix..."
    
    brew bundle upgrade --file /usr/share/ublue-os/homebrew/penguix-devops.Brewfile

# Install flatpak applications for penguix
[group('Apps')]
penguix-install-flatpak:
    #!/usr/bin/env bash
    echo "Installing flatpak applications for penguix..."
    
    brew bundle upgrade --file /usr/share/ublue-os/homebrew/penguix-flatpak.Brewfile