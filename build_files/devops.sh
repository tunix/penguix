#!/bin/bash

set -ouex pipefail

dnf install -y \
    telnet

systemctl enable podman.socket
systemctl disable pcscd.socket
