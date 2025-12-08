#!/bin/bash
# compile_wps.sh - Simple WPS compilation script following ~/models/wrf layout

# Base install layout is ${MODEL_ROOT:-$HOME/models/wrf}
MODEL_ROOT="${MODEL_ROOT:-$HOME/models/wrf}"
WRF_DIR="${WRF_DIR:-$MODEL_ROOT/WRF}"
WPS_DIR="${WPS_DIR:-$MODEL_ROOT/WPS}"

require_dir() {
    if [ ! -d "$1" ]; then
        echo "$2"
        exit 1
    fi
}

if [ ! -d "$WPS_DIR" ]; then
    echo "WPS directory not found at $WPS_DIR. Please install WPS under $MODEL_ROOT/WPS."
    exit 1
fi

LIBRARY_ROOT="${LIBRARY_ROOT:-$MODEL_ROOT/LIBRARIES}"
NETCDF_ROOT="${NETCDF_ROOT:-}"
GRIB2_ROOT="${GRIB2_ROOT:-}"

choose_root() {
    for candidate in "$@"; do
        if [ -n "$candidate" ] && [ -d "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

NETCDF_ROOT="$(choose_root "$NETCDF_ROOT" "$MODEL_ROOT/netcdf" "$LIBRARY_ROOT/netcdf-4.1.3")"
GRIB2_ROOT="$(choose_root "$GRIB2_ROOT" "$MODEL_ROOT/grib2" "$LIBRARY_ROOT/grib2")"

if [ -z "$NETCDF_ROOT" ]; then
    echo "NetCDF directory not found under $MODEL_ROOT or $LIBRARY_ROOT; run install_wrf_libraries.sh."
    exit 1
fi
if [ -z "$GRIB2_ROOT" ]; then
    echo "GRIB2 directory not found under $MODEL_ROOT or $LIBRARY_ROOT; run install_wrf_libraries.sh."
    exit 1
fi

require_dir "$NETCDF_ROOT/include" "NetCDF include directory missing at $NETCDF_ROOT/include. Run install_wrf_libraries.sh to build the shared libraries."
require_dir "$NETCDF_ROOT/lib" "NetCDF libraries missing at $NETCDF_ROOT/lib. Run install_wrf_libraries.sh to build the shared libraries."
require_dir "$GRIB2_ROOT/include" "GRIB2 include directory missing at $GRIB2_ROOT/include. Run install_wrf_libraries.sh to build the shared libraries (jasper/png)."
require_dir "$GRIB2_ROOT/lib" "GRIB2 libraries missing at $GRIB2_ROOT/lib. Run install_wrf_libraries.sh to build the shared libraries (jasper/png)."

export NETCDF="$NETCDF_ROOT"

cd "$WPS_DIR" || { echo "Failed to cd into $WPS_DIR"; exit 1; }

# Clean previous builds
echo "Cleaning previous builds..."
./clean 2>/dev/null || true

# Auto-detect best compiler option
echo "Detecting best compiler option..."
DEFAULT_GFORTRAN_OPTION="3"
DEFAULT_GFORTRAN_DMPAR_OPTION="35"
WPS_FORCE_DMPAR="${WPS_FORCE_DMPAR:-false}"
WPS_CONFIG_OPTION="${WPS_CONFIG_OPTION:-}"

if command -v ifort >/dev/null 2>&1; then
    OPTION="1"      # Intel ifort
    echo "Using option $OPTION (Intel ifort)"
elif command -v gfortran >/dev/null 2>&1; then
    if [ "$WPS_FORCE_DMPAR" = "true" ]; then
        OPTION="$DEFAULT_GFORTRAN_DMPAR_OPTION"
        echo "Using option $OPTION (GNU gfortran DM-parallel requested)"
    else
        OPTION="$DEFAULT_GFORTRAN_OPTION"
        echo "Using option $OPTION (GNU gfortran serial)"
    fi
else
    OPTION="35"      # Default fallback
    echo "No compiler detected, using default option $OPTION"
fi

if [ -n "$WPS_CONFIG_OPTION" ]; then
    OPTION="$WPS_CONFIG_OPTION"
    echo "Overriding configure option with WPS_CONFIG_OPTION=$OPTION"
fi
# Configure WPS
echo "Configuring WPS with option $OPTION..."
printf "%s\n" "$OPTION" | ./configure

# Ensure configure.wps matches the desired environment
if [ -f configure.wps ]; then
    if ! command -v g95 >/dev/null 2>&1 && command -v gfortran >/dev/null 2>&1 && grep -q '^SFC[[:space:]]*=.*g95' configure.wps; then
        echo "Adjusting configure.wps: replacing g95 with gfortran"
        sed -i 's|^SFC[[:space:]]*=.*|SFC                 = gfortran|' configure.wps
    fi
    if grep -q "/home/hector/model/wrf" configure.wps; then
        echo "Fixing configure.wps paths to use $MODEL_ROOT"
        sed -i "s|/home/hector/model/wrf|$MODEL_ROOT|g" configure.wps
    fi
    if grep -q "/home/hector/models/wrf/LIBRARIES/grib2" configure.wps; then
        echo "Pointing WPS grib2 settings at $GRIB2_ROOT"
        sed -i "s|/home/hector/models/wrf/LIBRARIES/grib2|$GRIB2_ROOT|g" configure.wps
    fi
    sed -i "s|^COMPRESSION_LIBS.*|COMPRESSION_LIBS    = -L$GRIB2_ROOT/lib -ljasper -lpng -lz|" configure.wps
    sed -i "s|^COMPRESSION_INC.*|COMPRESSION_INC     = -I$GRIB2_ROOT/include|" configure.wps
fi

# Set WRF directory (mirrors MODEL_ROOT convention)
echo "Setting WRF_DIR to: $WRF_DIR"
sed -i "s|WRF_DIR = .*|WRF_DIR = $WRF_DIR|" configure.wps 2>/dev/null || \
sed -i "s|WRF_DIR=.*|WRF_DIR=\"$WRF_DIR\"|" configure.wps 2>/dev/null || \
echo "WRF_DIR = $WRF_DIR" >> configure.wps

# Compile WPS
echo "Compiling WPS..."
./compile > compile.log 2>&1 &

# Monitor log
COMPILE_PID=$!
tail -f compile.log &
TAIL_PID=$!
wait $COMPILE_PID
kill $TAIL_PID 2>/dev/null

# Check if executables were created
if ls *.exe 2>/dev/null | grep -q .; then
    echo "Success! WPS executables created."
else
    echo "Warning: No .exe files found. Check compile.log for errors."
fi