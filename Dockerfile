# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install all system dependencies
RUN apt-get update && apt-get install -y \
    libnetcdff-dev \
    libnetcdf-dev \
    csh \
    gfortran \
    m4 \
    gcc \
    make \
    sudo \
    wget \
    unzip \
    curl \
    file \
    build-essential \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Create directory structure
RUN mkdir -p /opt/BUILD_WRF \
    && mkdir -p /opt/WRF \
    && mkdir -p /opt/WRF/LIBRARIES \
    && mkdir -p /opt/WRF/TESTS_PKGS \
    && mkdir -p /opt/WRF/WRF_CHEM_FILES
#copy all content from Install-WRF-Chem 
COPY Install-WRF-Chem/LIBRARIES /opt/WRF/LIBRARIES
COPY Install-WRF-Chem/TESTS_PKGS /opt/WRF/TESTS_PKGS
COPY Install-WRF-Chem/WRF_CHEM_FILES /opt/WRF/WRF_CHEM_FILES

# Set environment variables
ENV DIR=/opt/WRF/LIBRARIES
ENV CC=gcc
ENV CXX=g++
ENV FC=gfortran
ENV CFLAGS=-m64
ENV F77=gfortran
ENV FFLAGS=-m64

# Install libraries
RUN cd $DIR && \
    tar -xzf netcdf-4.1.3.tar.gz && \
    cd netcdf-4.1.3 && \
    ./configure --prefix=$DIR/netcdf --disable-dap --disable-netcdf-4 --disable-shared && \
    make && \
    make install && \
    cd .. && \
    rm netcdf-4.1.3.tar.gz
#set NETCDF environment variable
ENV PATH="${DIR}/netcdf/bin:${PATH}" 
ENV NETCDF="${DIR}/netcdf" 
#installing mpich 
RUN cd $DIR && \
    tar -xzf mpich-4.3.0.tar.gz && \
    cd mpich-4.3.0 && \
    ./configure --prefix=/opt/WRF/LIBRARIES/mpich \
        FFLAGS="-fallow-argument-mismatch" \
        FCFLAGS="-fallow-argument-mismatch" && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm mpich-4.3.0.tar.gz

ENV PATH="${DIR}/mpich/bin:${PATH}"
#install zlib
RUN cd $DIR && \
    tar -xzf zlib-1.2.7.tar.gz && \
    cd zlib-1.2.7 && \
    ./configure --prefix=$DIR/grib2 && \
    make && \
    make install && \
    cd .. && \
    rm zlib-1.2.7.tar.gz

ENV LDFLAGS="-L${DIR}/grib2/lib"
ENV CPPFLAGS="-I${DIR}/grib2/include"

#installing libpng
RUN cd $DIR && \
    tar -xzf libpng-1.2.50.tar.gz && \
    cd libpng-1.2.50 && \
    ./configure --prefix=$DIR/grib2 && \
    make && \
    make install && \
    cd .. && \
    rm libpng-1.2.50.tar.gz

#install jasper
RUN cd $DIR && \
    unzip -q -o jasper-1.900.1.zip && \
    find jasper-1.900.1 -name "._*" -delete && \  
    cd jasper-1.900.1 && \
    ./configure --prefix=$DIR/grib2 && \
    make && \
    make install && \
    cd .. && \
    rm jasper-1.900.1.zip

ENV JASPERLIB="${DIR}/grib2/lib" \
    JASPERINC="${DIR}/grib2/include"


# Create BUILD_WRF directory and copy test files
RUN mkdir -p /opt/BUILD_WRF/TESTS && \
    tar -xvf /opt/WRF/TESTS_PKGS/Fortran_C_NETCDF_MPI_tests.tar -C /opt/BUILD_WRF/TESTS && \
    cp /opt/WRF/LIBRARIES/netcdf/include/netcdf.inc /opt/BUILD_WRF/TESTS/

# Run NetCDF+MPI tests
RUN cd /opt/BUILD_WRF/TESTS && \
    gfortran -c 01_fortran+c+netcdf_f.f && \
    gcc -c 01_fortran+c+netcdf_c.c && \
    gfortran 01_fortran+c+netcdf_f.o 01_fortran+c+netcdf_c.o -L${NETCDF}/lib -lnetcdff -lnetcdf && \
    ./a.out && \
    mpif90 -c 02_fortran+c+netcdf+mpi_f.f && \
    mpicc -c 02_fortran+c+netcdf+mpi_c.c && \
    mpif90 02_fortran+c+netcdf+mpi_f.o 02_fortran+c+netcdf+mpi_c.o -L${NETCDF}/lib -lnetcdff -lnetcdf && \
    mpirun -np 2 ./a.out

# Install WRF-Chem
# ----------------------------
# INSTALACIÓN WRF (ETAPA SEPARADA)
# ----------------------------

# Copia los archivos de WRF (solo si cambian)
COPY Install-WRF-Chem/WRF_CHEM_FILES/WRF.tar.gz /opt/BUILD_WRF/WRF.TAR.gz
ENV WRF_EM_CORE=1 \
    WRF_NMM_CORE=0 \
    WRF_CHEM=1 \
    WRF_KPP=0 
    
RUN cd /opt/BUILD_WRF && \
    tar -xzf WRF.TAR.gz && \
    cd /opt/BUILD_WRF/WRF && \
    ./clean -a && \
    { echo "34"; echo ""; echo ""; sleep 1; } | ./configure 2>&1 | tee configure.log && \
    [ -f configure.wrf ] || { echo "Configuración fallida"; cat configure.log; exit 1; } && \
    ./compile em_real > compile.log 2>&1 || { echo "Compilación fallida"; tail -n 100 compile.log; exit 1; }

#install WPS
COPY Install-WRF-Chem/WRF_CHEM_FILES/WPS.tar.gz /opt/BUILD_WRF/WPS.tar.gz
ENV WRF_DIR=/opt/BUILD_WRF/WRF \
    WPS_DIR=/opt/BUILD_WRF/WPS
 
    
RUN cd /opt/BUILD_WRF && \
    tar -xzf WPS.TAR.gz && \
    cd ${WPS_DIR} && \
    ./clean -a && \
    printf "1\n" | ./configure && \
    sed -i "s|WRF_DIR=.*|WRF_DIR=\"${WRF_DIR}\"|" configure.wps && \
    ./compile > compile.log 2>&1 && \
    grep -q "Error" compile.log && { echo "Error en compilación"; exit 1; } || echo "Compilación exitosa"

CMD ["/bin/bash"]