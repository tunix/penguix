#!/bin/bash

set -ouex pipefail

rpm-ostree install \
    system76-driver \
    system76-firmware \
    system76-keyboard-configurator \
    firmware-manager \
    telnet

systemctl disable pcscd.socket

/tmp/1password.sh
