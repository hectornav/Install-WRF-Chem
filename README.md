# WRF-Chem Installation Helper

The scripts in this repository automate a repeatable WRF + WPS install that respects a shared `~/models/wrf` layout.
The goal is a self-contained set of helpers that build dependencies, configure compilers, and place the final binaries under `~/models/wrf/{WRF,WPS}` so experiments can be re-run without polluting the system tree.

## Workspace layout
```
Install-WRF-Chem/
├── check_compilers.sh
├── check_hardware.sh
├── common.sh
├── compile_wrf.sh
├── compile_wps.sh   # Builds WPS using MODEL_ROOT defaults
├── create_directories.sh
├── install_system_libraries.sh
├── install_wrf_libraries.sh
├── main.sh          # Orchestrates the entire install
├── run_netcdf_mpi_tests.sh
├── run_tests.sh
├── LIBRARIES/       # Helper scripts and archives used during library builds
├── TESTS_PKGS/
└── WRF_CHEM_FILES/  # Tarballs for WRF/WPS and supplemental data
```

### Runtime layout expectations
Scripts now assume the following directories exist under `MODEL_ROOT` (default: `$HOME/models/wrf`):
- `${MODEL_ROOT}/WRF` — the WRF source tree to be compiled.
- `${MODEL_ROOT}/WPS` — the WPS source tree used by `compile_wps.sh`.
- `${MODEL_ROOT}/LIBRARIES` (optional) — packaged helpers; rebuilt dependencies may live here while runtime libs are symlinked or referenced through `NETCDF_ROOT`/`GRIB2_ROOT`.

The `install_wrf_libraries.sh` script now populates `${MODEL_ROOT}/netcdf`, `${MODEL_ROOT}/grib2`, and `${MODEL_ROOT}/mpich`, so `compile_wps.sh` dynamically discovers them.

## Environment variables you can set
- `MODEL_ROOT` (default `$HOME/models/wrf`): base directory for the WRF/WPS layout.
- `WRF_DIR`, `WPS_DIR`: override source locations if they live outside `MODEL_ROOT`.
- `LIBRARY_ROOT`: fallback for dependency archives (defaults to `$MODEL_ROOT/LIBRARIES`).
- `NETCDF_ROOT`: override the NetCDF install directory. If unset, `compile_wps.sh` looks through `$MODEL_ROOT/netcdf` and `$LIBRARY_ROOT/netcdf-4.1.3`.
- `GRIB2_ROOT`: same override logic for the Jasper/PNG/grib2 set.
- `WPS_FORCE_DMPAR`: set to `true` to compile the DM-parallel WPS option (configure option `35`).
- `WPS_CONFIG_OPTION`: directly specify any option number for `./configure`; this takes precedence over the auto-detected choice.

## Installation flow
Run the scripts in order to avoid missing dependencies. Each script writes logs under the working directory so you can diagnose failures.
1. `./check_hardware.sh` — validates CPU cores, RAM, and available disk space.
2. `./create_directories.sh` — prepares `BUILD_WRF`, `LIBRARIES`, and workspace folders.
3. `./install_system_libraries.sh` — installs system packages like `gfortran`, `csh`, `perl`, etc.
4. `./check_compilers.sh` — confirms the available compilers and standard locations.
5. `./install_wrf_libraries.sh` — builds NetCDF, MPICH, Jasper, libpng, and Zlib under the shared layout.
6. `./run_netcdf_mpi_tests.sh` — runs the bundled NetCDF/MPI test suites to ensure the ecosystem is healthy.
7. `./compile_wrf.sh` — compiles the WRF model using the same `MODEL_ROOT` conventions.
8. `./compile_wps.sh` — compiles the WPS tree; this script now enforces `MODEL_ROOT` paths and checks for NetCDF/GRIB2 libraries before running.
9. Optionally run `./run_tests.sh` once the build finishes.

**Important:** always source `wrf_env.sh` (or run `./LIBRARIES/wrf_env.sh`) before compiling so the environment variables (e.g., `PATH`, `LD_LIBRARY_PATH`, `NETCDF`, `NETCDF_FORTRAN`) are available.

## Using `compile_wps.sh`
The script now:
- exits if `$WPS_DIR` does not exist under `MODEL_ROOT`; you must extract `WPS.tar.gz` (stored in `WRF_CHEM_FILES/`) into `$MODEL_ROOT/WPS`.
- auto-discovers installed dependencies under `$MODEL_ROOT/netcdf` and `$MODEL_ROOT/grib2`, but you can override via `NETCDF_ROOT`/`GRIB2_ROOT`.
- exports `NETCDF` for `configure.wps`, ensures `WRF_DIR` is pointed at `${MODEL_ROOT}/WRF`, rewrites the compression settings, and replaces any residual `g95` references.
- reuses the old compiler choice logic but now defaults to gfortran serial option `3`; set `WPS_FORCE_DMPAR=true` to compile the dmpar option or `WPS_CONFIG_OPTION=<n>` for another target.
- runs `./compile` with logging piped to `compile.log` and tailing for live feedback.

Example usage:
```bash
MODEL_ROOT="$HOME/models/wrf" \
NETCDF_ROOT="$HOME/models/wrf/netcdf" \
GRIB2_ROOT="$HOME/models/wrf/grib2" \
WPS_FORCE_DMPAR=false \
./compile_wps.sh
```
If you need the DM-parallel build for MPI, override `WPS_FORCE_DMPAR=true`. If you want to select option `5` explicitly, set `WPS_CONFIG_OPTION=5`.

## Expected outputs
- `WPS/geogrid.exe`, `ungrib.exe`, and `metgrid.exe` (plus utilities such as `int2nc.exe`) are created inside the `$MODEL_ROOT/WPS` tree.
- `compile.log` in `$MODEL_ROOT/WPS` records the full compiler output.

## Troubleshooting
- **Missing NetCDF/GRIB2**: rerun `./install_wrf_libraries.sh` and ensure the directories `${MODEL_ROOT}/netcdf/{bin,include,lib}` and `${MODEL_ROOT}/grib2/{include,lib}` exist.
- **`-lg2_4`, `-ljasper`, or `GOMP_` undefined**: make sure MPI/OpenMP-enabled versions of libraries were built. The script uses `mpif90` wrapper, so `mpich` must be built before WPS.
- **Compiler mismatches**: inspect `configure.wps`; the script tries to replace `g95` with `gfortran` and adjust `WRF_DIR`. If your system uses a different compiler, set `WPS_CONFIG_OPTION` accordingly.
- **Environment variables**: source `wrf_env.sh` or export `PATH` and `LD_LIBRARY_PATH` pointing at `${MODEL_ROOT}/netcdf/bin` and `${MODEL_ROOT}/netcdf/lib` before running the compile scripts.

## Branching guidance
When working on this project, create feature branches (e.g., `feature/structured-wps`) from `auto-wrf`, make your changes, and push once the build passes. The current branch contains the updates to `compile_wps.sh` and this README.

For any questions, contact the repository owner (Hector Navarro Barboza).
