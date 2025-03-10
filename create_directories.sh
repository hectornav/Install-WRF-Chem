#!/bin/bash

# create_directories.sh
# Create directories for WRF installation with user-defined or default names.
# Saves the directory paths to a configuration file for use by other scripts.

# Default directory names one folder above the current directory
CURRENT_DIR=$(pwd)
LEVEL_DOWN_DIR=$(dirname "$CURRENT_DIR")  # One level down from the current directory

DEFAULT_INSTALL_DIR="$LEVEL_DOWN_DIR/BUILD_WRF"

# Prompt the user for directory names
read -p "Enter installation directory [Press Enter for default: $DEFAULT_INSTALL_DIR]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}  # Use default if user presses Enter


# Create directories
echo "Creating directories..."
mkdir -p "$INSTALL_DIR" "$LIBRARIES_DIR" "$INSTALL_DIR/TESTS"

# Save directory paths to a configuration file
CONFIG_FILE="$INSTALL_DIR/wrf_config.cfg"
echo "INSTALL_DIR=$INSTALL_DIR" > "$CONFIG_FILE"
echo "LIBRARIES_DIR=$LIBRARIES_DIR" >> "$CONFIG_FILE"

# Confirm directory creation
echo "Directories created:"
echo "Installation directory: $INSTALL_DIR"
echo "TESTS directory: $INSTALL_DIR/TESTS"
echo "Configuration file saved to: $CONFIG_FILE"