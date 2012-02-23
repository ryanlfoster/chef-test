#!/bin/bash

# This runs as root on the server

PACKAGES="${PACKAGES} libreoffice*.*"
PACKAGES="${PACKAGES} openjdk*.*"

apt-get remove ${PACKAGES} -y

