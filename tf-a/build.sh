#!/usr/bin/env bash

set -e

export CROSS_COMPILE="$GCC5_AARCH64_PREFIX"

cd tf-a/arm-trusted-firmware-cix-odp
make -j$PARALLELISM \
    PLAT=sky1 \
    SPD=opteed \
    DEBUG=1 \
    BUILD_BASE="${PATH_OUT}/tf-a" \
    CIX_BOARD=evb \
    SMP=1 \
    MBEDTLS_DIR="${MBEDTLS_PATH}" \
    TRUSTED_BOARD_BOOT=1 \
    ENABLE_FEAT_HCX=1 \
    ARM_ROTPK_LOCATION=devel_rsa \
    ROT_KEY=plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem \
    LDFLAGS="--no-warn-rwx-segments" \
    bl31

cp -f "${PATH_OUT}/tf-a/sky1/debug/bl31.bin" "${PATH_OUT}/tf-a.bin"
cp -f "${PATH_OUT}/tf-a/sky1/debug/bl31/bl31.elf" "${PATH_OUT}/bl31.elf"
