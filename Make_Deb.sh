#!/bin/bash
# This script is used to make a .deb package from a source code
# First install fpm
sudo apt install ruby ruby-dev rubygems build-essential -y
sudo gem install --no-ri --no-rdoc fpm
# Then make the .deb package
fpm -s dir -t deb -n mypackage -v 1.0.0 /app