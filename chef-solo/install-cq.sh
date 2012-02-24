#!/bin/bash

cd /tmp
wget http://10.183.33.173/dev-setup/server-setup/functions.sh
chmod +x functions.sh
. functions.sh

setupHostsFile

setupTimezone

setupCq

