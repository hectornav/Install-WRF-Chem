#!/bin/bash

# compile_wps.sh
# Compile WPS from local files.

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define the installation directory (one level up from the script directory)
INSTALL_DIR="$SCRIPT_DIR/../BUILD_WRF"

# Navigate to the WPS directory
echo "Navigating to WPS directory..."
cd "$INSTALL_DIR/WPS" || { echo "WPS directory not found!"; exit 1; }

# Clean previous builds
echo "Cleaning previous builds..."
./clean

# Configure WPS (automatically select option 1)
echo "Configuring WPS..."
printf "1\n" | ./configure

# Modify configure.wps to set the correct WRF_DIR
echo "Updating configure.wps..."
sed -i "s|WRF_DIR=.*|WRF_DIR=\"$SCRIPT_DIR/../BUILD_WRF/WRF\"|" configure.wps

# Compile WPS
echo "Compiling WPS..."
./compile >& compile.log &

# Monitor the compilation log
echo "Monitoring compilation log..."
tail -f compile.log