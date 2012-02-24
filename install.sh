#!/bin/bash

# This runs as root on the server

# the chef binary isn't here on ubuntu... find it and fix this path
#chef_binary=/var/lib/gems/1.9.1/bin/chef-solo
chef_binary=/usr/local/bin/chef-solo

# Are we on a vanilla system?
if ! test -f "$chef_binary"; then
    export DEBIAN_FRONTEND=noninteractive
    # Upgrade headlessly (this is only safe-ish on vanilla systems)
    apt-get update &&
    apt-get -o Dpkg::Options::="--force-confnew" \
        --force-yes -fuy dist-upgrade &&
    # Install curl
    apt-get install -y curl
    # Install Ruby and Chef
    # (use rvm instead of ubuntu packages?)
    #apt-get install -y ruby1.9.1 ruby1.9.1-dev make &&
    #sudo gem1.9.1 install --no-rdoc --no-ri chef --version 0.10.0
    apt-get install -y ruby1.8 ruby1.8-dev rubygems make &&
    sudo gem1.8 install --no-rdoc --no-ri chef --version 0.10.0
fi &&

"$chef_binary" -c solo.rb -j solo.json
"$chef_binary" -c solo.rb -j java.json
"$chef_binary" -c solo.rb -j maven.json

