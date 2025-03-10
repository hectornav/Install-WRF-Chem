#!/bin/bash

# install_system_libraries.sh
# Install necessary system libraries for WRF.

echo "Installing necessary system libraries..."
sudo apt-get update
sudo apt install libnetcdff-dev libnetcdf-dev
sudo apt-get install -y csh gfortran m4 build-essential