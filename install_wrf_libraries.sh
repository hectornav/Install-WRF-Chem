#!/bin/bash

# install_wrf_libraries.sh
# Install and configure libraries required for WRF-Chem.

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # Directory where the script is located
LIBRARIES_DIR="$SCRIPT_DIR/LIBRARIES"  # LIBRARIES folder is in the same directory as the script
DIR="$LIBRARIES_DIR"  # Set DIR to the LIBRARIES directory

# Check if LIBRARIES directory exists
if [ ! -d "$LIBRARIES_DIR" ]; then
    echo "Error: LIBRARIES directory not found at $LIBRARIES_DIR."
    exit 1
fi

# Function to configure environment variables
configure_environment() {
    echo "Configuring environment variables..."

    # Add WRF environment variables to .bashrc
    cat <<EOL >> ~/.bashrc
# WRF environment variables
export DIR="$LIBRARIES_DIR"
export CC=gcc
export CXX=g++
export FC=gfortran
export CFLAGS=-m64
export F77=gfortran
export FFLAGS=-m64
EOL

    # Activate the new environment variables
    source ~/.bashrc
}

# Function to install NetCDF
install_netcdf() {
    echo "Installing NetCDF..."
    # Check if NetCDF directory exists
    if [ ! -d "$LIBRARIES_DIR/netcdf-4.1.3" ]; then
        tar -xzf "$LIBRARIES_DIR/netcdf-4.1.3.tar.gz" -C "$LIBRARIES_DIR"
    fi   
    # Change to the NetCDF directory
    cd "$LIBRARIES_DIR/netcdf-4.1.3"

    # Configure NetCDF
    ./configure --prefix="$DIR/netcdf" --disable-dap --disable-netcdf-4 --disable-shared
    if [ $? -ne 0 ]; then
        echo "Error: NetCDF configuration failed."
        exit 1
    fi

    # Compile and install NetCDF
    sudo make
    if [ $? -ne 0 ]; then
        echo "Error: NetCDF compilation failed."
        exit 1
    fi

    sudo make install
    if [ $? -ne 0 ]; then
        echo "Error: NetCDF installation failed."
        exit 1
    fi

    # Add NetCDF paths to .bashrc
    cat <<EOL >> ~/.bashrc
export PATH="$DIR/netcdf/bin:\$PATH"
export NETCDF="$DIR/netcdf"
EOL

    # Activate the new environment variables
    source ~/.bashrc

    echo "NetCDF installation complete."
}

# Function to install MPICH
install_mpich() {
    echo "Installing MPICH..."
    # Check if MPICH directory exists
    if [ ! -d "$LIBRARIES_DIR/mpich-3.4.0" ]; then
        tar -xzf "$LIBRARIES_DIR/mpich-3.4.0.tar.gz" -C "$LIBRARIES_DIR"
    fi
    cd "$LIBRARIES_DIR/mpich-3.4.0"
    #cleaning 
    sudo make clean

    # Check gfortran version
    GFORTRAIN_VERSION=$(gfortran -dumpversion | cut -d. -f1)
    if [ "$GFORTRAIN_VERSION" -ge 10 ]; then
        echo "gfortran version is 10 or higher. Adding -fallow-argument-mismatch flag."
        export FFLAGS="-fallow-argument-mismatch"
        export FCFLAGS="-fallow-argument-mismatch"
    fi

    # Configure MPICH
    #sudo ./configure --prefix="$DIR/mpich"
    sudo ./configure FFLAGS="-fallow-argument-mismatch"

    if [ $? -ne 0 ]; then
        echo "Error: MPICH configuration failed."
        exit 1
    fi

    # Compile MPICH
    sudo make
    if [ $? -ne 0 ]; then
        echo "Error: MPICH compilation failed."
        exit 1
    fi

    # Install MPICH with sudo
    sudo make install
    if [ $? -ne 0 ]; then
        echo "Error: MPICH installation failed."
        exit 1
    fi

    # Add MPICH paths to .bashrc
    cat <<EOL >> ~/.bashrc
export PATH="$DIR/mpich/bin:\$PATH"
EOL

    # Activate the new environment variables
    source ~/.bashrc

    echo "MPICH installation complete."
}

# Function to install Zlib
install_zlib() {
    echo "Installing Zlib..."
    # Check if Zlib directory exists
    if [ ! -d "$LIBRARIES_DIR/zlib-1.2.7" ]; then
        tar -xzf "$LIBRARIES_DIR/zlib-1.2.7.tar.gz" -C "$LIBRARIES_DIR"
    fi
    cd "$LIBRARIES_DIR/zlib-1.2.7"

    # Configure Zlib
    ./configure --prefix="$DIR/grib2"
    if [ $? -ne 0 ]; then
        echo "Error: Zlib configuration failed."
        exit 1
    fi

    # Compile and install Zlib
    sudo make
    if [ $? -ne 0 ]; then
        echo "Error: Zlib compilation failed."
        exit 1
    fi

    sudo make install
    if [ $? -ne 0 ]; then
        echo "Error: Zlib installation failed."
        exit 1
    fi

    # Add Zlib paths to .bashrc
    cat <<EOL >> ~/.bashrc
export LDFLAGS="-L$DIR/grib2/lib"
export CPPFLAGS="-I$DIR/grib2/include"
EOL

    # Activate the new environment variables
    source ~/.bashrc

    echo "Zlib installation complete."
}

# Function to install libpng
install_libpng() {
    echo "Installing libpng..."
    # Check if libpng directory exists
    if [ ! -d "$LIBRARIES_DIR/libpng-1.2.50" ]; then
        tar -xzf "$LIBRARIES_DIR/libpng-1.2.50.tar.gz" -C "$LIBRARIES_DIR"
    fi
    cd "$LIBRARIES_DIR/libpng-1.2.50"

    # Configure libpng
    ./configure --prefix="$DIR/grib2"
    if [ $? -ne 0 ]; then
        echo "Error: libpng configuration failed."
        exit 1
    fi

    # Compile and install libpng
    sudo make
    if [ $? -ne 0 ]; then
        echo "Error: libpng compilation failed."
        exit 1
    fi

    sudo make install
    if [ $? -ne 0 ]; then
        echo "Error: libpng installation failed."
        exit 1
    fi

    echo "libpng installation complete."
}

# Function to install Jasper
install_jasper() {
    echo "Installing Jasper..."
    # Check if Jasper directory exists, jasper-1.900.1 is in zip format not tar.gz
    if [ ! -d "$LIBRARIES_DIR/jasper-1.900.1" ]; then
        unzip "$LIBRARIES_DIR/jasper-1.900.1.zip" -d "$LIBRARIES_DIR"
    fi
    cd "$LIBRARIES_DIR/jasper-1.900.1"

    # Configure Jasper
    ./configure --prefix="$DIR/grib2"
    if [ $? -ne 0 ]; then
        echo "Error: Jasper configuration failed."
        exit 1
    fi

    # Compile and install Jasper
    sudo make
    if [ $? -ne 0 ]; then
        echo "Error: Jasper compilation failed."
        exit 1
    fi

    sudo make install
    if [ $? -ne 0 ]; then
        echo "Error: Jasper installation failed."
        exit 1
    fi

    # Add Jasper paths to .bashrc
    cat <<EOL >> ~/.bashrc
export JASPERLIB="$DIR/grib2/lib"
export JASPERINC="$DIR/grib2/include"
EOL

    # Activate the new environment variables
    source ~/.bashrc

    echo "Jasper installation complete."
}

# Main script execution
configure_environment
install_netcdf
install_mpich
install_zlib
install_libpng
install_jasper

echo "All libraries installed and configured successfully!"