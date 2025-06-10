#!/bin/bash

set -ouex pipefail

KERNEL="$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
RELEASE="$(rpm -E '%fedora')"

# RPMFUSION Dependent AKMODS
dnf -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${RELEASE}".noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${RELEASE}".noarch.rpm

dnf -y install \
    akmod-intel-ipu6 \
    libcamera-qcam

akmods --force --kernels "${KERNEL}" --kmod intel-ipu6

dnf -y remove rpmfusion-free-release rpmfusion-nonfree-release
