#!/bin/bash

# compile_wrf.sh
# Compile WRF from local files and handle decompression of required files.

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # Directory where the script is located
INSTALL_DIR="$SCRIPT_DIR/../BUILD_WRF"  # INSTALL_DIR is one level down from the script
WRF_CHEM_FILES_DIR="$SCRIPT_DIR/WRF_CHEM_FILES"  # Directory containing WRF-Chem files

echo "Setting up WRF environment..."

# Ensure BUILD_WRF directory exists
mkdir -p "$INSTALL_DIR"

# Decompress WRF.tar.gz inside BUILD_WRF
echo "Decompressing WRF.tar.gz into BUILD_WRF..."
tar -xzf "$WRF_CHEM_FILES_DIR/WRF.tar.gz" -C "$INSTALL_DIR"

# Decompress WPS.tar.gz inside BUILD_WRF
echo "Decompressing WPS.tar.gz into BUILD_WRF..."
tar -xzf "$WRF_CHEM_FILES_DIR/WPS.tar.gz" -C "$INSTALL_DIR"

# Navigate to the decompressed WRFV3 directory
cd "$INSTALL_DIR/WRF" || { echo "Failed to enter WRF directory."; exit 1; }

# Set environment variables for WRF
export WRF_EM_CORE=1
export WRF_NMM_CORE=0
export WRF_CHEM=1
export WRF_KPP=0

# Clean WRF
echo "Cleaning WRF..."
./clean -a

# Configure WRF non-interactively
echo "Configuring WRF (non-interactive)..."
{
  echo "34"  # Select option 34 (GNU compilers with basic nesting and chemistry)
  echo ""   # Accept default value for nesting
  echo ""   # Accept default value for nesting
} | ./configure

# Check if configuration succeeded
if [ $? -ne 0 ]; then
  echo "Error: WRF configuration failed."
  exit 1
fi

# Compile WRF
echo "Compiling WRF (this may take a while)..."
./compile em_real > compile.log 2>&1 &

# Monitor the compilation log
echo "Monitoring compilation log..."
tail -f compile.log

# Wait for the compilation to finish
wait $!

# Check if compilation succeeded
if grep -q "Executables successfully built" compile.log; then
  echo "WRF compilation complete!"
else
  echo "Error: WRF compilation failed. Check compile.log for details."
  exit 1
fi