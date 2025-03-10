#!/bin/bash

# run_netcdf_mpi_tests.sh
# This script automates the process of running Fortran + C + NetCDF + MPI tests.

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # Directory where the script is located
TESTS_PKGS_DIR="$SCRIPT_DIR/TESTS_PKGS"  # Folder containing the .tar packages
BUILD_WRF_DIR="$SCRIPT_DIR/../BUILD_WRF"  # BUILD_WRF is one level down from the script
TESTS_DIR="$BUILD_WRF_DIR/TESTS"  # TESTS folder inside BUILD_WRF

# Check if TESTS_PKGS directory exists
if [ ! -d "$TESTS_PKGS_DIR" ]; then
    echo "Error: TESTS_PKGS directory not found at $TESTS_PKGS_DIR."
    exit 1
fi

# Check if TESTS directory exists
if [ ! -d "$TESTS_DIR" ]; then
    echo "Error: TESTS directory not found at $TESTS_DIR."
    exit 1
fi

# Check if NETCDF environment variable is set
if [ -z "$NETCDF" ]; then
    echo "Error: NETCDF environment variable is not set."
    exit 1
fi

# Navigate to TESTS directory
cd "$TESTS_DIR"

# Decompress Fortran_C_NETCDF_MPI_tests.tar
echo "Decompressing Fortran_C_NETCDF_MPI_tests.tar..."
tar -xvf "$TESTS_PKGS_DIR/Fortran_C_NETCDF_MPI_tests.tar"
if [ $? -ne 0 ]; then
    echo "Error: Failed to decompress Fortran_C_NETCDF_MPI_tests.tar."
    exit 1
fi

# Copy netcdf.inc to the current directory
echo "Copying netcdf.inc..."
cp "${NETCDF}/include/netcdf.inc" .
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy netcdf.inc."
    exit 1
fi

# Run Test 1: Fortran + C + NetCDF
echo "Running Test 1: Fortran + C + NetCDF..."
gfortran -c 01_fortran+c+netcdf_f.f
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile 01_fortran+c+netcdf_f.f."
    exit 1
fi

gcc -c 01_fortran+c+netcdf_c.c
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile 01_fortran+c+netcdf_c.c."
    exit 1
fi

gfortran 01_fortran+c+netcdf_f.o 01_fortran+c+netcdf_c.o -L${NETCDF}/lib -lnetcdff -lnetcdf
if [ $? -ne 0 ]; then
    echo "Error: Failed to link 01_fortran+c+netcdf_f.o and 01_fortran+c+netcdf_c.o."
    exit 1
fi

./a.out
if [ $? -ne 0 ]; then
    echo "Error: Test 1 failed."
    exit 1
fi
echo "SUCCESS: Test 1 fortran + c + netcdf passed."

# Run Test 2: Fortran + C + NetCDF + MPI
echo "Running Test 2: Fortran + C + NetCDF + MPI..."
mpif90 -c 02_fortran+c+netcdf+mpi_f.f
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile 02_fortran+c+netcdf+mpi_f.f."
    exit 1
fi

mpicc -c 02_fortran+c+netcdf+mpi_c.c
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile 02_fortran+c+netcdf+mpi_c.c."
    exit 1
fi

mpif90 02_fortran+c+netcdf+mpi_f.o 02_fortran+c+netcdf+mpi_c.o -L${NETCDF}/lib -lnetcdff -lnetcdf
if [ $? -ne 0 ]; then
    echo "Error: Failed to link 02_fortran+c+netcdf+mpi_f.o and 02_fortran+c+netcdf+mpi_c.o."
    exit 1
fi

mpirun ./a.out
if [ $? -ne 0 ]; then
    echo "Error: Test 2 failed."
    exit 1
fi
echo "SUCCESS: Test 2 fortran + c + netcdf + mpi passed."

echo "All tests completed successfully!"