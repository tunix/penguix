# vim: set ft=just :
#######################
### penguix-system.just
#######################

# Sets shell for user
[group('System')]
change-shell shell='/usr/bin/fish':
    sudo usermod --shell {{shell}} ${USER}

alias chsh := change-shell