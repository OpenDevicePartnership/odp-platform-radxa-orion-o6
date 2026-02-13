#!/usr/bin/env bash

set -e

CFG_TEE_CORE_LOG_LEVEL=2
DEBUG=1

export PLATFORM=cix
export PLATFORM_FLAVOR=sky1
export CFG_STMM_PATH=${PATH_BUILD_BOOTCHAIN_BINS}/BL32_AP_EFI_STMM.fd

cd tee/op-tee-cix-odp
make -j${PARALLELISM} \
    O="${PATH_BUILD_OUTPUT}/tee" \
    ARCH=arm \
    CROSS_COMPILE64="${GCC5_AARCH64_PREFIX}" \
    CFG_ARM64_core=y \
    CFG_USER_TA_TARGETS=ta_arm64 \
    LDFLAGS="--no-warn-rwx-segments" \
    all

cp -f "${PATH_BUILD_OUTPUT}/tee/core/tee-raw.bin" "${PATH_BUILD_BOOTCHAIN_BINS}"
