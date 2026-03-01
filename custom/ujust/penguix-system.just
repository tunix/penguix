# vim: set ft=just :
#######################
### penguix-system.just
#######################

user := env_var("USER)

# Sets shell for user
[group('System')]
change-shell shell='/usr/bin/fish':
    sudo usermod --shell {{shell}} {{user}}

alias chsh := change-shell