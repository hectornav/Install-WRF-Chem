#!/bin/bash

# install_wrf_libraries.sh
# Install and configure libraries required for WRF-Chem.

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # Directory where the script is located

# source common helpers if available
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/common.sh"
fi

# Default install base if not provided: keep installations in the user's home under models/wrf
if [ -z "$INSTALL_BASE" ]; then
    INSTALL_BASE="$HOME/models/wrf"
fi

# Default LIBRARIES_DIR: prefer an explicit env var, otherwise place it next to INSTALL_BASE
LIBRARIES_DIR="${LIBRARIES_DIR:-$INSTALL_BASE/LIBRARIES}"

# Repo-local libraries (where the archive files originally live)
REPO_LIBRARIES_DIR="$SCRIPT_DIR/LIBRARIES"
# Environment file placed inside INSTALL_BASE to avoid modifying repo files directly
ENV_FILE="$INSTALL_BASE/wrf_env.sh"

# Ask for sudo once and keep credentials alive during the script (we DO NOT store the password)
ask_sudo() {
    # If sudo already has credentials cached, continue. Otherwise prompt the user.
    if sudo -n true 2>/dev/null; then
        return 0
    fi

    echo "Some installation steps require sudo. You'll be prompted for your password."
    if ! sudo -v; then
        echo "Unable to obtain sudo privileges. Exiting."
        exit 1
    fi

    # Keep-alive: refresh sudo timestamp until the script exits
    ( while true; do
        sleep 60
        sudo -n true 2>/dev/null || true
    done ) &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

# Remove any previously added WRF env blocks from user rc files
clean_old_wrfenv() {
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc" ]; then
            if grep -q ">>> WRF_ENV START >>>" "$rc" 2>/dev/null; then
                sed -i '/>>> WRF_ENV START >>>/,/<<< WRF_ENV END <<</d' "$rc" || true
            fi
        fi
    done
}

# Helper: set or replace an environment variable line in the env file
set_env_var() {
    local key="$1"
    local value="$2"
    # Ensure env file exists
    touch "$ENV_FILE"
    if grep -q "^export ${key}=" "$ENV_FILE" 2>/dev/null; then
        # replace existing line (portable sed -i)
        sed -i -e "s|^export ${key}=.*|export ${key}=${value}|" "$ENV_FILE" || true
    else
        echo "export ${key}=${value}" >> "$ENV_FILE"
    fi
}

# Helper: add a directory to a PATH-like variable in env file if not already present
add_path_entry() {
    local key="$1"
    local newpath="$2"
    touch "$ENV_FILE"
    # read current value from file if present
    local cur
    cur=$(grep "^export ${key}=" "$ENV_FILE" 2>/dev/null | sed -E "s|^export ${key}=||") || true
    # strip surrounding quotes (if any)
    cur=$(echo "$cur" | sed -e 's/^"//' -e 's/"$//')
    if [ -z "$cur" ]; then
        echo "export ${key}=${newpath}:\$${key}" >> "$ENV_FILE"
        return
    fi
    if echo ":${cur}:" | grep -q ":${newpath}:"; then
        return
    fi
    # prepend newpath
    sed -i -e "s|^export ${key}=\(.*\)|export ${key}=${newpath}:\1|" "$ENV_FILE" || true
}

# Add a small block to source the generated env file from user rc files (if not already present)
add_source_to_rc() {
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc" ]; then
            if ! grep -q ">>> WRF_ENV START >>>" "$rc" 2>/dev/null; then
                cat <<EOL >> "$rc"
# >>> WRF_ENV START >>>
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi
# <<< WRF_ENV END <<<
EOL
            fi
        else
            # create rc file and add source block
            cat <<EOL > "$rc"
# >>> WRF_ENV START >>>
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi
# <<< WRF_ENV END <<<
EOL
        fi
    done
}

# Check if LIBRARIES directory exists
if [ ! -d "$LIBRARIES_DIR" ]; then
    error "Error: LIBRARIES directory not found at $LIBRARIES_DIR."
    exit 1
fi

# Ensure an archive is extracted if the expected directory is missing
ensure_extracted() {
    local name="$1"
    # Destination for extracted sources: INSTALL_BASE/LIBRARIES
    local dest_dir="$INSTALL_BASE/LIBRARIES"
    mkdir -p "$dest_dir"

    # Prefer an already-extracted source inside INSTALL_BASE/LIBRARIES
    if [ -d "$dest_dir/$name" ]; then
        cd "$dest_dir/$name" || { error "Error: failed to cd into $dest_dir/$name"; exit 1; }
        return 0
    fi

    # If there's a directory inside the repo LIBRARIES, copy it to INSTALL_BASE/LIBRARIES to avoid modifying the repo
    if [ -d "$REPO_LIBRARIES_DIR/$name" ]; then
        info "Found source in repo at $REPO_LIBRARIES_DIR/$name — copying to $dest_dir"
        cp -a "$REPO_LIBRARIES_DIR/$name" "$dest_dir/"
        cd "$dest_dir/$name" || { error "Error: failed to cd into $dest_dir/$name"; exit 1; }
        return 0
    fi

    info "Directory for $name not found — searching for archives in $REPO_LIBRARIES_DIR, $LIBRARIES_DIR and $INSTALL_BASE..."

    # Search for archives in repo LIBRARIES, LIBRARIES_DIR and INSTALL_BASE
    shopt -s nullglob
    local archives=(
        "$REPO_LIBRARIES_DIR/$name"*.tar.gz "$REPO_LIBRARIES_DIR/$name"*.tgz "$REPO_LIBRARIES_DIR/$name"*.zip
        "$LIBRARIES_DIR/$name"*.tar.gz "$LIBRARIES_DIR/$name"*.tgz "$LIBRARIES_DIR/$name"*.zip
        "$INSTALL_BASE/$name"*.tar.gz "$INSTALL_BASE/$name"*.tgz "$INSTALL_BASE/$name"*.zip
        "$REPO_LIBRARIES_DIR/$name.tar.gz" "$REPO_LIBRARIES_DIR/$name.zip"
        "$LIBRARIES_DIR/$name.tar.gz" "$LIBRARIES_DIR/$name.zip"
    )
    shopt -u nullglob

    if [ ${#archives[@]} -eq 0 ]; then
        error "Error: no archive found for $name in $REPO_LIBRARIES_DIR, $LIBRARIES_DIR or $INSTALL_BASE"
        exit 1
    fi

    local archive="${archives[0]}"
    info "Found archive $archive — extracting into $dest_dir"
    case "$archive" in
        *.zip)
            unzip -o "$archive" -d "$dest_dir"
            ;;
        *.tar.gz|*.tgz)
            tar -xzf "$archive" -C "$dest_dir"
            ;;
        *)
            error "Unsupported archive: $archive"
            exit 1
            ;;
    esac

    # Try to locate the extracted directory. Prefer exact match, otherwise pick first match name*
    if [ -d "$dest_dir/$name" ]; then
        cd "$dest_dir/$name" || { error "Error: failed to cd into $dest_dir/$name"; exit 1; }
        return 0
    fi

    # fallback: find a directory starting with name
    local found
    found=$(find "$dest_dir" -maxdepth 1 -type d -name "$name*" | head -n 1 || true)
    if [ -n "$found" ]; then
        cd "$found" || { error "Error: failed to cd into $found"; exit 1; }
        return 0
    fi

    error "Error: extraction did not produce a source directory for $name in $dest_dir"
    exit 1
}

# Function to configure environment variables
configure_environment() {
    echo "Configuring environment variables..."

    # Clean any old entries and create a fresh environment file
    clean_old_wrfenv

# ensure INSTALL_BASE exists before writing env
    mkdir -p "$INSTALL_BASE"

    # Initialize env file header (overwrite) and write canonical variables via helpers
    cat > "$ENV_FILE" <<'EOL'
# WRF environment variables (generated by install_wrf_libraries.sh)
# Do not edit this file directly; it is managed by the installer scripts.
EOL

    # canonical entries
    set_env_var DIR "\"$LIBRARIES_DIR\""
    set_env_var CC "gcc"
    set_env_var CXX "g++"
    set_env_var FC "gfortran"
    set_env_var CFLAGS "-m64"
    set_env_var F77 "gfortran"
    set_env_var FFLAGS "-m64"

    # Source the env file in the current shell for the running script
    if [ -f "$ENV_FILE" ]; then
        # shellcheck source=/dev/null
        # shellcheck disable=SC1090
        source "$ENV_FILE"
    fi
}

# Function to install NetCDF
install_netcdf() {
    info "Installing NetCDF..."
    # Skip if already installed
    if [ -d "$INSTALL_BASE/netcdf" ] && [ -x "$INSTALL_BASE/netcdf/bin/nc-config" ]; then
        success "NetCDF already installed in $INSTALL_BASE/netcdf. Skipping."
        return 0
    fi

    ensure_extracted "netcdf-4.1.3"

    # Configure NetCDF
    ./configure --prefix="$INSTALL_BASE/netcdf" --disable-dap --disable-netcdf-4 --disable-shared
    if [ $? -ne 0 ]; then
        error "Error: NetCDF configuration failed."
        exit 1
    fi

    # Compile and install NetCDF
    make
    if [ $? -ne 0 ]; then
        error "Error: NetCDF compilation failed."
        exit 1
    fi

    make install
    if [ $? -ne 0 ]; then
        error "Error: NetCDF installation failed."
        exit 1
    fi

    # Add NetCDF paths to env file (idempotent)
    add_path_entry PATH "\"$INSTALL_BASE/netcdf/bin\""
    set_env_var NETCDF "\"$INSTALL_BASE/netcdf\""

    # Source updated env file in the running script
    if [ -f "$ENV_FILE" ]; then
        # shellcheck source=/dev/null
        # shellcheck disable=SC1090
        source "$ENV_FILE"
    fi

    success "NetCDF installation complete."
}

# Function to install MPICH
install_mpich() {
    info "Installing MPICH..."
    # Skip if already installed
    if [ -d "$INSTALL_BASE/mpich" ] && [ -x "$INSTALL_BASE/mpich/bin/mpirun" ]; then
        success "MPICH already installed in $INSTALL_BASE/mpich. Skipping."
        return 0
    fi

    ensure_extracted "mpich-3.0.4"

    ask_sudo
    sudo make clean || true

    # Detectar versión de gfortran y aplicar flags
    GFORTRAIN_VERSION=$(gfortran -dumpversion | cut -d. -f1)
    if [ "$GFORTRAIN_VERSION" -ge 10 ]; then
        export FFLAGS="-fallow-argument-mismatch"
        export FCFLAGS="-fallow-argument-mismatch"
    fi

    # Solución al error "multiple definition of HYD_pmcd_pmip"
    export CFLAGS="-fcommon"
    export CC=gcc

    ./configure --prefix="$INSTALL_BASE/mpich" CFLAGS="$CFLAGS"
    if [ $? -ne 0 ]; then
        error "Error: MPICH configuration failed."
        exit 1
    fi

    make
    if [ $? -ne 0 ]; then
        error "Error: MPICH compilation failed."
        exit 1
    fi

    sudo make install
    if [ $? -ne 0 ]; then
        error "Error: MPICH installation failed."
        exit 1
    fi

    add_path_entry PATH "\"$INSTALL_BASE/mpich/bin\""
    if [ -f "$ENV_FILE" ]; then
        # shellcheck disable=SC1090
        source "$ENV_FILE"
    fi

    success "MPICH installation complete."
}

# Function to install Zlib
install_zlib() {
    info "Installing Zlib..."
    # Skip if already installed
    if [ -d "$INSTALL_BASE/grib2" ] && [ -f "$INSTALL_BASE/grib2/lib/libz.a" ] || [ -f "$INSTALL_BASE/grib2/lib/libz.so" ]; then
        success "Zlib (grib2) already installed in $INSTALL_BASE/grib2. Skipping."
        return 0
    fi

    ensure_extracted "zlib-1.2.7"

    # Configure Zlib
    ./configure --prefix="$INSTALL_BASE/grib2"
    if [ $? -ne 0 ]; then
        error "Error: Zlib configuration failed."
        exit 1
    fi

    # Compile and install Zlib
    # compile
    make
    if [ $? -ne 0 ]; then
        error "Error: Zlib compilation failed."
        exit 1
    fi

    # install (may require sudo)
    ask_sudo
    sudo make install
    if [ $? -ne 0 ]; then
        error "Error: Zlib installation failed."
        exit 1
    fi

    # Add Zlib paths to env file
    set_env_var LDFLAGS "\"-L$INSTALL_BASE/grib2/lib\""
    set_env_var CPPFLAGS "\"-I$INSTALL_BASE/grib2/include\""

    if [ -f "$ENV_FILE" ]; then
        # shellcheck disable=SC1090
        source "$ENV_FILE"
    fi

    success "Zlib installation complete."
}

# Function to install libpng
install_libpng() {
    info "Installing libpng..."
    # Skip if already installed
    if [ -d "$INSTALL_BASE/grib2" ] && [ -f "$INSTALL_BASE/grib2/lib/libpng.a" ] || [ -f "$INSTALL_BASE/grib2/lib/libpng.so" ]; then
        success "libpng already installed in $INSTALL_BASE/grib2. Skipping."
        return 0
    fi

    ensure_extracted "libpng-1.2.50"

    # Configure libpng
    ./configure --prefix="$INSTALL_BASE/grib2"
    if [ $? -ne 0 ]; then
        error "Error: libpng configuration failed."
        exit 1
    fi

    # Compile and install libpng
    make
    if [ $? -ne 0 ]; then
        error "Error: libpng compilation failed."
        exit 1
    fi

    ask_sudo
    sudo make install
    if [ $? -ne 0 ]; then
        error "Error: libpng installation failed."
        exit 1
    fi

    success "libpng installation complete."
}

# Function to install Jasper
install_jasper() {
    info "Installing Jasper..."
    # Skip if already installed
    if [ -d "$INSTALL_BASE/grib2" ] && [ -f "$INSTALL_BASE/grib2/lib/libjasper.a" ] || [ -f "$INSTALL_BASE/grib2/lib/libjasper.so" ]; then
        success "Jasper already installed in $INSTALL_BASE/grib2. Skipping."
        return 0
    fi

    ensure_extracted "jasper-1.900.1"

    # Configure Jasper
    ./configure --prefix="$INSTALL_BASE/grib2"
    if [ $? -ne 0 ]; then
        error "Error: Jasper configuration failed."
        exit 1
    fi

    # Compile and install Jasper
    make
    if [ $? -ne 0 ]; then
        error "Error: Jasper compilation failed."
        exit 1
    fi

    ask_sudo
    sudo make install
    if [ $? -ne 0 ]; then
        error "Error: Jasper installation failed."
        exit 1
    fi

    # Add Jasper paths to env file
    set_env_var JASPERLIB "\"$INSTALL_BASE/grib2/lib\""
    set_env_var JASPERINC "\"$INSTALL_BASE/grib2/include\""

    if [ -f "$ENV_FILE" ]; then
        # shellcheck disable=SC1090
        source "$ENV_FILE"
    fi

    success "Jasper installation complete."
}

# Main script execution
configure_environment
install_netcdf
install_mpich
install_zlib
install_libpng
install_jasper
# Ensure user's shell rc files source the generated env file (after installation)
add_source_to_rc

echo "All libraries installed and configured successfully!"