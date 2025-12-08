#!/bin/bash

# create_directories.sh
# Create directories for WRF installation with user-defined or default names.
# Saves the directory paths to a configuration file for use by other scripts.

#!/bin/bash

# create_directories.sh
# Create directories for WRF installation with user-defined or default names.
# Saves the directory paths to a configuration file for use by other scripts.

# Location of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source color helpers if present
if [ -f "$SCRIPT_DIR/common.sh" ]; then
	# shellcheck source=/dev/null
	source "$SCRIPT_DIR/common.sh"
fi

# Default base where WRF will be installed (can be overridden by INSTALL_BASE env var)
DEFAULT_BASE="${INSTALL_BASE:-$HOME/models/wrf}"
DEFAULT_INSTALL_DIR="$DEFAULT_BASE/BUILD_WRF"

# Prompt the user for directory names
read -p "Enter installation directory [Press Enter for default: $DEFAULT_INSTALL_DIR]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}  # Use default if user presses Enter

# Derive LIBRARIES_DIR next to the install base (so we don't unpack inside the repo)
LIBRARIES_DIR="$(dirname "$INSTALL_DIR")/LIBRARIES"

# Create directories
info "Creating directories..."
mkdir -p "$INSTALL_DIR" "$LIBRARIES_DIR" "$INSTALL_DIR/TESTS"

# Save directory paths to a configuration file
CONFIG_FILE="$INSTALL_DIR/wrf_config.cfg"
echo "INSTALL_DIR=$INSTALL_DIR" > "$CONFIG_FILE"
echo "LIBRARIES_DIR=$LIBRARIES_DIR" >> "$CONFIG_FILE"

# Confirm directory creation
success "Directories created:"
echo "Installation directory: $INSTALL_DIR"
echo "TESTS directory: $INSTALL_DIR/TESTS"
echo "Configuration file saved to: $CONFIG_FILE"