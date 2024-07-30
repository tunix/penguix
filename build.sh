#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

rpm-ostree install \
    system76-keyboard-configurator \
    telnet

systemctl disable pcscd.socket

/tmp/1password.sh

grep -E '^libvirt:' /usr/lib/group | tee -a /etc/group
