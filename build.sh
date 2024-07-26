#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

rpm-ostree install \
    system76-keyboard-configurator \
    telnet

systemctl disable pcscd.socket

/tmp/1password.sh