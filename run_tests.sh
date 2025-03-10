#!/bin/bash

# run_tests.sh
# This script automates the creation of the TESTS folder, decompresses test files, and runs the tests.

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # Directory where the script is located
BUILD_WRF_DIR="$SCRIPT_DIR/../BUILD_WRF"  # BUILD_WRF is one level down from the script
TESTS_PKGS_DIR="$SCRIPT_DIR/TESTS_PKGS"  # Folder containing the .tar packages
TESTS_DIR="$BUILD_WRF_DIR/TESTS"  # TESTS folder inside BUILD_WRF

#make a source .bashrc to get the environment variables
source ~/.bashrc

# Check if BUILD_WRF directory exists
if [ ! -d "$BUILD_WRF_DIR" ]; then
    echo "Error: BUILD_WRF directory not found at $BUILD_WRF_DIR."
    exit 1
fi

# Check if TESTS_PKGS directory exists
if [ ! -d "$TESTS_PKGS_DIR" ]; then
    echo "Error: TESTS_PKGS directory not found at $TESTS_PKGS_DIR."
    exit 1
fi

# Create TESTS directory inside BUILD_WRF
echo "Creating TESTS directory..."
mkdir -p "$TESTS_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create TESTS directory."
    exit 1
fi

# Navigate to TESTS directory
cd "$TESTS_DIR"

# Copy and decompress Fortran_C_tests.tar
echo "Copying and decompressing Fortran_C_tests.tar..."
cp "$TESTS_PKGS_DIR/Fortran_C_tests.tar" .
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy Fortran_C_tests.tar."
    exit 1
fi

tar -xf Fortran_C_tests.tar
if [ $? -ne 0 ]; then
    echo "Error: Failed to decompress Fortran_C_tests.tar."
    exit 1
fi

# Run Test 1: Fixed format Fortran
echo "Running Test 1: Fixed format Fortran..."
gfortran TEST_1_fortran_only_fixed.f
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile TEST_1_fortran_only_fixed.f."
    exit 1
fi

./a.out
if [ $? -ne 0 ]; then
    echo "Error: Test 1 failed."
    exit 1
fi
echo "SUCCESS: Test 1 fortran only fixed format passed."

# Run Test 2: Free format Fortran
echo "Running Test 2: Free format Fortran..."
gfortran TEST_2_fortran_only_free.f90
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile TEST_2_fortran_only_free.f90."
    exit 1
fi

./a.out
if [ $? -ne 0 ]; then
    echo "Error: Test 2 failed."
    exit 1
fi
echo "SUCCESS: Test 2 fortran only free format passed."

# Run Test 3: C only
echo "Running Test 3: C only..."
gcc TEST_3_c_only.c
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile TEST_3_c_only.c."
    exit 1
fi

./a.out
if [ $? -ne 0 ]; then
    echo "Error: Test 3 failed."
    exit 1
fi
echo "SUCCESS: Test 3 C only passed."

# Run Test 4: Fortran calling C
echo "Running Test 4: Fortran calling C..."
gcc -c -m64 TEST_4_fortran+c_c.c
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile TEST_4_fortran+c_c.c."
    exit 1
fi

gfortran -c -m64 TEST_4_fortran+c_f.f90
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile TEST_4_fortran+c_f.f90."
    exit 1
fi

gfortran -m64 TEST_4_fortran+c_f.o TEST_4_fortran+c_c.o
if [ $? -ne 0 ]; then
    echo "Error: Failed to link TEST_4_fortran+c_f.o and TEST_4_fortran+c_c.o."
    exit 1
fi

./a.out
if [ $? -ne 0 ]; then
    echo "Error: Test 4 failed."
    exit 1
fi
echo "SUCCESS: Test 4 fortran calling c passed."

# Run Test 5: csh compiler
echo "Running Test 5: csh compiler..."
csh TEST_csh.csh
if [ $? -ne 0 ]; then
    echo "Error: Test 5 failed."
    exit 1
fi
echo "SUCCESS: Test 5 csh test passed."

# Run Test 6: perl compiler
echo "Running Test 6: perl compiler..."
./TEST_perl.pl
if [ $? -ne 0 ]; then
    echo "Error: Test 6 failed."
    exit 1
fi
echo "SUCCESS: Test 6 perl test passed."

# Run Test 7: sh compiler
echo "Running Test 7: sh compiler..."
./TEST_sh.sh
if [ $? -ne 0 ]; then
    echo "Error: Test 7 failed."
    exit 1
fi
echo "SUCCESS: Test 7 sh test passed."

echo "All tests completed successfully!"