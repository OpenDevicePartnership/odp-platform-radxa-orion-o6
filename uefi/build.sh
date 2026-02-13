#!/usr/bin/env bash

set -e

export WORKSPACE="$PWD/uefi"
export PACKAGES_PATH=$WORKSPACE/edk2:$WORKSPACE/platform:$TOOLCHAIN_WORKSPACE/common/edk2-platforms-cix-odp:$TOOLCHAIN_WORKSPACE/common/edk2-non-osi-cix-odp
export IASL_PREFIX="${TOOLCHAIN_WORKSPACE}/tools/acpica/generate/unix/bin/"

cd ${WORKSPACE}

if [ ! -e edk2/BaseTools/Source/C/bin/VolInfo ]; then
    make -C edk2/BaseTools
fi
if [ ! -e ../tools/acpica/generate/unix/bin/iasl ]; then
    make -C "${TOOLCHAIN_WORKSPACE}/tools/acpica"
fi
source edk2/edksetup.sh --reconfig

BUILD_DATE=`date +%VM%y%m%d%H%M%SN`
COMMIT_HASH=`git rev-parse --short=12 HEAD`

build \
    -a AARCH64 \
    -t GCC5 \
    -p platform/O6.dsc \
    -b DEBUG \
    -D BOARD_NAME=evb \
    -D PATH_BUILD_OUTPUT=$PATH_BUILD_OUTPUT \
    -D BUILD_DATE=$BUILD_DATE \
    -D COMMIT_HASH=$COMMIT_HASH \
    -D SMP_ENABLE=1 \
    -D ACPI_BOOT_ENABLE=1 \
    -D FASTBOOT_LOAD=disable \
    -D VARIABLE_TYPE=SPI \
    -D STANDARD_MM=TRUE \
    -D SYSTEM_LOADER=common

cp ${PATH_BUILD_OUTPUT}/uefi/DEBUG_GCC5/FV/SKY1_BL33_UEFI.fd "${PATH_BUILD_BOOTCHAIN_BINS}"
