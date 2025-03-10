#!/bin/bash

# check_compilers.sh
# Check compiler versions for WRF installation.
# Ensures GCC version is greater than 4.x.x and provides clear feedback.

# Function to check GCC version
check_gcc_version() {
    echo "Checking GCC version..."
    local gcc_version
    gcc_version=$(gcc -dumpversion | cut -f1 -d.)
    
    if [ -z "$gcc_version" ]; then
        echo "Error: GCC is not installed or not found in the system PATH."
        exit 1
    fi

    if [ "$gcc_version" -lt 4 ]; then
        echo "Error: Your system has GCC version $gcc_version."
        echo "WRF requires GCC 4.0 or higher."
        exit 1
    else
        echo "GCC version $gcc_version is compatible."
    fi
}

# Function to check compiler versions
check_compilers() {
    echo "Checking compiler versions..."
    
    # Check gfortran
    if ! command -v gfortran &> /dev/null; then
        echo "Error: gfortran is not installed or not found in the system PATH."
        exit 1
    else
        echo "gfortran is installed:"
        gfortran --version
    fi

    # Check gcc
    if ! command -v gcc &> /dev/null; then
        echo "Error: gcc is not installed or not found in the system PATH."
        exit 1
    else
        echo "gcc is installed:"
        gcc --version
    fi

    # Check cpp
    if ! command -v cpp &> /dev/null; then
        echo "Error: cpp is not installed or not found in the system PATH."
        exit 1
    else
        echo "cpp is installed:"
        cpp --version
    fi
}

# Main execution
main() {
    echo "Starting compiler checks for WRF installation..."
    check_compilers
    check_gcc_version
    echo "All compiler checks passed successfully."
}

# Run the main function
main