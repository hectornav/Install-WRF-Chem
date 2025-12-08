#!/bin/bash

# main.sh
# Main script to run all WRF installation tasks in the specified order.

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source common helpers (colors)
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/common.sh"
fi

# Prefer INSTALL_BASE from env file if present; otherwise default under user's home
ENV_FILE_DEFAULT="$HOME/models/wrf/wrf_env.sh"
if [ -f "${ENV_FILE:-$ENV_FILE_DEFAULT}" ]; then
    # shellcheck source=/dev/null
    source "${ENV_FILE:-$ENV_FILE_DEFAULT}"
fi

# Define the installation directory (fallback)
INSTALL_DIR="${INSTALL_DIR:-$INSTALL_BASE}"
if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="$SCRIPT_DIR/../BUILD_WRF"
fi

# Function to run a script and check for errors
run_script() {
    local script_name="$1"
    if [ "${DRY_RUN:-0}" = "1" ]; then
        info "DRY RUN: would run $script_name"
        echo "-- Actions found in $script_name --"
        # show likely dangerous or important commands from the script (no execution)
        grep -nE "\b(tar|configure|make|sudo|cp|mv|rm|mkdir|./compile|./configure|source)\b" "$SCRIPT_DIR/$script_name" || true
        echo "----------------------------------------"
        return 0
    fi

    info "Running $script_name..."
    if ! "$SCRIPT_DIR/$script_name"; then
        error "Error: $script_name failed!"
        exit 1
    fi
    success "$script_name completed successfully."
    echo "----------------------------------------"
}

# Step 1: Check hardware capabilities
run_script "check_hardware.sh"

# Step 2: Create directories
run_script "create_directories.sh"

# Step 3: Install system libraries
run_script "install_system_libraries.sh"

# Step 4: Check compiler versions
run_script "check_compilers.sh"

# Step 5: Install WRF libraries
run_script "install_wrf_libraries.sh"

# Step 6: Run NetCDF and MPI tests
run_script "run_netcdf_mpi_tests.sh"

# Step 7: Compile WRF
run_script "compile_wrf.sh"

# Step 8: Compile WPS
run_script "compile_wps.sh"

echo "WRF and WPS installation complete!"