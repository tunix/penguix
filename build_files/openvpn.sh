#!/bin/bash

set -ouex pipefail

dnf5 -y copr enable \
    dsommers/openvpn3 \
    grzegorz-gutowski/openvpn3-indicator

dnf5 install -y \
    openvpn3-client \
    openvpn3-indicator
