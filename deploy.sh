#!/bin/bash

# Install a base VM using the normal Ubuntu iso in VirtualBox.
# Install openssh-server on VM.
# Update the following line in `sudo visudo` before using this.
#   %admin ALL=NOPASSWD: ALL
# Add port forwarding to the VM for ssh (e.g. host ip, port 2022 to guest ip, port 22)
# Run ./deploy.sh vagrant@hostIp hostForwardedPort
# Running this script will update the Linux kernel (almost certainly), so can we install
#   the VirtualBox Guest Additions via chef?

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
sudo bash remove.sh &&
sudo bash install.sh'

# add `sudo bash remove.sh` before calling install.sh to remove extra crap like libreoffice*.*
# so we don't spend time updating a lot of stuff that we don't care about.
