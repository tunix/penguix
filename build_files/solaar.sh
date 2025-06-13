#!/bin/bash

set -ouex pipefail

dnf install -y \
    solaar \
    solaar-udev
