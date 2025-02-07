#!/bin/bash

set -ouex pipefail

dnf5 -y copr enable pgdev/ghostty

dnf5 install -y \
  ghostty
