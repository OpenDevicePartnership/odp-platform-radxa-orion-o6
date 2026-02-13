#!/usr/bin/env bash

set -e

export CROSS_COMPILE="$GCC5_AARCH64_PREFIX"
export MBEDTLS_PATH="${TOOLCHAIN_WORKSPACE}/tf-a/mbedtls"

cd tf-a/arm-trusted-firmware-cix-odp
make -j$PARALLELISM \
    PLAT=sky1 \
    SPD=opteed \
    DEBUG=1 \
    BUILD_BASE="${PATH_BUILD_OUTPUT}/tf-a" \
    CIX_BOARD=evb \
    SMP=1 \
    MBEDTLS_DIR="${MBEDTLS_PATH}" \
    TRUSTED_BOARD_BOOT=1 \
    ENABLE_FEAT_HCX=1 \
    ARM_ROTPK_LOCATION=devel_rsa \
    ROT_KEY=plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem \
    LDFLAGS="--no-warn-rwx-segments" \
    bl31

cp -f "${PATH_BUILD_OUTPUT}/tf-a/sky1/debug/bl31.bin" "${PATH_BUILD_BOOTCHAIN_BINS}"
cp -f "${PATH_BUILD_OUTPUT}/tf-a/sky1/debug/bl31/bl31.elf" "${PATH_BUILD_BOOTCHAIN_BINS}"
