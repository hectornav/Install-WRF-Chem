#!/bin/bash

# main.sh
# Main script to run all WRF installation tasks in the specified order.

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define the installation directory (one level up from the script directory)
INSTALL_DIR="$SCRIPT_DIR/../BUILD_WRF"

# Function to run a script and check for errors
run_script() {
    local script_name="$1"
    echo "Running $script_name..."
    if ! "$SCRIPT_DIR/$script_name"; then
        echo "Error: $script_name failed!"
        exit 1
    fi
    echo "$script_name completed successfully."
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