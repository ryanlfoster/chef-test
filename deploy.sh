#!/bin/bash

# 1. Install openssh-server on VM.
# 2. Update the following line in `sudo visudo` before using this.
#    %admin ALL=NOPASSWD: ALL
# 3. Add port forwarding to the VM for ssh (e.g. host ip, port 2022 to guest ip, port 22)

# Usage: ./deploy.sh [host] [port]

host="${1:-vagrant@192.168.0.1}"
port="${2}"

# The host key might change when we instantiate a new VM, so
# we remove (-R) the old host key from known_hosts
ssh-keygen -R "${host#*@}" 2> /dev/null

tar cj . | ssh -o 'StrictHostKeyChecking no' -p ${port} "${host}" '
sudo rm -rf ~/chef &&
mkdir ~/chef &&
cd ~/chef &&
tar xj &&
sudo bash install.sh'

