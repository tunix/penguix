#!/bin/bash

set -ouex pipefail

rpm-ostree install \
    system76-keyboard-configurator \
    telnet

systemctl disable pcscd.socket

/tmp/1password.sh
