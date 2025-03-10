#!/bin/bash

# check_hardware.sh
# Check hardware capabilities for WRF installation.

echo "Checking hardware capabilities for WRF installation..."

# Check CPU cores
CPU_CORES=$(nproc)
if [ "$CPU_CORES" -lt 2 ]; then
    echo "Warning: Your system has fewer than 2 CPU cores. WRF may run slowly."
else
    echo "CPU cores: $CPU_CORES"
fi

# Check RAM
RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
if [ "$RAM_GB" -lt 4 ]; then
    echo "Warning: Your system has less than 4GB of RAM. WRF may run out of memory."
else
    echo "RAM: $RAM_GB GB"
fi

# Check disk space
DISK_SPACE=$(df -h / | awk '/\//{print $4}')
echo "Disk space available: $DISK_SPACE"

# Check Linux distribution
LINUX_DISTRO=$(lsb_release -d | awk -F"\t" '{print $2}')
echo "Linux distribution: $LINUX_DISTRO"

# Check kernel version
KERNEL_VERSION=$(uname -r)
echo "Kernel version: $KERNEL_VERSION"

echo "Hardware check complete."