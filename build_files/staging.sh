#!/bin/bash

set -ouex pipefail

# ublue staging repo needed for ghostty, etc
dnf5 -y copr enable ublue-os/staging

dnf5 install -y \
  ghostty
