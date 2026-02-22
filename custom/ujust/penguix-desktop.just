# vim: set ft=just :
#######################
### penguix-desktop.just
#######################

# Enables touchpad history navigation scroll & wayland support for Brave Browser
[group('Fixes')]
brave-wayland-fixes:
    mkdir -p $HOME/.var/app/com.brave.Browser/config

    cat <<EOF > $HOME/.var/app/com.brave.Browser/config/brave-flags.conf
    --enable-features=UseOzonePlatform,TouchpadOverscrollHistoryNavigation
    --ozone-platform=wayland
    EOF

# Sync's dconf settings for local user
[group('Desktop')]
dconf-sync:
    dconf update