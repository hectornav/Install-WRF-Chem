# WRF Installation Tutorial

This tutorial provides a step-by-step guide to install the Weather Research and Forecasting (WRF) model and its pre-processing system (WPS) on a Linux-based system. The installation process is automated using modular Bash scripts.

Created by **Hector Navarro Barboza** (h.navarrobarboza@gmail.com).

---

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Directory Structure](#directory-structure)
4. [Installation Steps](#installation-steps)
5. [Script Details](#script-details)
6. [Running the Installation](#running-the-installation)
7. [Troubleshooting](#troubleshooting)
8. [Contact](#contact)

---

## Overview

This tutorial automates the installation of WRF and WPS using a set of modular Bash scripts. The scripts handle tasks such as:
- Checking hardware capabilities.
- Installing system libraries.
- Compiling WRF and WPS.
- Running tests to ensure compatibility.

The installation process is divided into small, reusable scripts, making it easy to debug and customize.

### **IMPORTANT**

The folder `WRF_CHEM_FILES` contains essential files for the installation. You **must** download it and place it inside the repository folder. Follow these steps:

1. Download the folder from this link:  
   [WRF_CHEM_FILES on Google Drive](https://drive.google.com/drive/folders/1-6BQ7A-RTu7s7VggeJ5qeldBOQew31DY?usp=drive_link)
2. Place the downloaded folder inside the root of this repository.
---

## Prerequisites

Before starting, ensure your system meets the following requirements:
- **Operating System**: Linux (Ubuntu/Debian recommended).
- **Disk Space**: At least 20 GB of free space.
- **RAM**: Minimum 4 GB (8 GB or more recommended).
- **CPU**: Multi-core processor (4 cores or more recommended).
- **Internet Connection**: Required for downloading dependencies (if not using local packages).

---

---

## Installation Steps

The installation process follows a strict order:

1. **Check Hardware**: Verify system resources (CPU, RAM, disk space).
2. **Create Directories**: Set up the directory structure for WRF and WPS.
3. **Install System Libraries**: Install required system libraries (e.g., `gfortran`, `csh`).
4. **Check Compilers**: Verify the versions of `gcc`, `gfortran`, and `cpp`.
5. **Install WRF Libraries**: Install libraries like NetCDF, MPICH, Jasper, etc.
6. **Run NetCDF and MPI Tests**: Ensure compatibility with NetCDF and MPI.
7. **Compile WRF**: Build the WRF model.
8. **Compile WPS**: Build the WPS pre-processing system.

---

## Script Details

Each script performs a specific task:

| Script Name                  | Description                                                                 |
|------------------------------|-----------------------------------------------------------------------------|
| `check_hardware.sh`          | Checks CPU cores, RAM, and disk space.                                     |
| `create_directories.sh`      | Creates the `BUILD_WRF` and `LIBRARIES` directories.                       |
| `install_system_libraries.sh`| Installs system libraries like `gfortran`, `csh`, and `build-essential`.   |
| `check_compilers.sh`         | Verifies the versions of `gcc`, `gfortran`, and `cpp`.                     |
| `install_wrf_libraries.sh`   | Installs WRF dependencies (NetCDF, MPICH, Jasper, etc.).                   |
| `run_netcdf_mpi_tests.sh`    | Runs tests to ensure NetCDF and MPI are working correctly.                 |
| `compile_wrf.sh`             | Compiles the WRF model.                                                    |
| `compile_wps.sh`             | Compiles the WPS pre-processing system.                                    |
| `main.sh`                    | Runs all scripts in the correct order.                                     |

---

## Running the Installation

1. **Clone or Download the Scripts**:
   - Download the scripts or clone the repository (if available).

2. **Make Scripts Executable**:
   ```bash
   chmod +x scripts/*.sh
3. **Run the Main Script**:
    ./scripts/main.sh

4. **Monitor the Installation**:
   - The script will log progress and stop if any step fails.

# Troubleshooting

## Common Issues

### Permission Denied
- Ensure all scripts are executable:  
  ```sh
  chmod +x scripts/*.sh

### Missing Dependencies
- Ensure all system libraries are installed by running:
  ./install_system_libraries.sh

### Compilation Errors
  - Check the compile.log file in the respective directory:
    - BUILD_WRF/WRF
    - BUILD_WRF/WPS

### Environment Variables
 - Ensure the .bashrc file is correctly updated with the necessary environment variables.