#!/bin/bash

set -ouex pipefail

# source: https://github.com/lenovo/lenovo-wwan-unlock

semodule -i /var/opt/fcc_lenovo/*.cil

systemctl enable lenovo-cfgservice.service
