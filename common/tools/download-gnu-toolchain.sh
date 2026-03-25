#!/bin/bash
# Script to download (if not present) and verify the proper version of the GNU toolchain is available.  It uses the
# ODP_PATH_GCC5_PREFIX environment variable to determine where the toolchain should be installed and the gcc
# executable name.
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

# =====================================================================================================================
# GCC toolchain version information
# =====================================================================================================================
GCC_VERSION="13.2.rel1"
GCC_ARCHIVE="arm-gnu-toolchain-${GCC_VERSION}-x86_64-aarch64-none-elf.tar.xz"
GCC_URL="https://developer.arm.com/-/media/Files/downloads/gnu/${GCC_VERSION}/binrel/${GCC_ARCHIVE}"
GCC_SHA256="7fe7b8548258f079d6ce9be9144d2a10bd2bf93b551dafbf20fe7f2e44e014b8"

# Exit immediately if a command exits with a non-zero status
set -e

# Expectation is that ODP_PATH_GCC5_PREFIX is already set to where the gcc executable will be.  Use that variable data
# to determine where the toolchain should be installed.
# Example:
#    ODP_PATH_GCC5_PREFIX = $(ODP_PATH_COMMON)/tools/gnu-toolchain/bin/aarch64-none-elf-
#    GNU_TOOLCHAIN_PATH   = $(ODP_PATH_COMMON)/tools/gnu-toolchain
GNU_TOOLCHAIN_PATH="$(dirname "$(dirname "${ODP_PATH_GCC5_PREFIX}")")"

# On any error during the download phase, this message will be displayed to show how they can manually download
error_exit() {
    echo "ERROR: Failed to download and extract the GNU toolchain"
    echo ""
    echo "If your environment does not have access to the internet, the image can be downloaded manually:"
    echo "  URL:  ${GCC_URL}"
    echo ""
    echo "Then decompressed to the proper directory:"
    echo "  CMD:  tar xf ${GCC_ARCHIVE} -C ${GNU_TOOLCHAIN_PATH} --strip-components=1"
    echo ""
    exit 1
}

# Download the package if the directory does not exist
if [ ! -d "${GNU_TOOLCHAIN_PATH}" ]; then
    trap error_exit ERR

    mkdir -p "${GNU_TOOLCHAIN_PATH}"

    # Download the compressed archive and verify the sha256 hash
    wget --progress=bar:force -O "${GNU_TOOLCHAIN_PATH}/${GCC_ARCHIVE}" "${GCC_URL}"
    echo "${GCC_SHA256}  ${GNU_TOOLCHAIN_PATH}/${GCC_ARCHIVE}" | sha256sum -c -

    # Extract the archive to the toolchain directory and remove the archive
    tar xf "${GNU_TOOLCHAIN_PATH}/${GCC_ARCHIVE}" -C "${GNU_TOOLCHAIN_PATH}" --strip-components=1
    rm "${GNU_TOOLCHAIN_PATH}/${GCC_ARCHIVE}"

    trap - ERR
fi

# Run gcc using the environment variable to confirm the defined path and version are correct
INSTALLED_VERSION=$("${ODP_PATH_GCC5_PREFIX}gcc" --version 2>/dev/null | head -1)
if echo "${INSTALLED_VERSION}" | grep -q "${GCC_VERSION}"; then
    echo "Using GNU Toolchain ${GCC_VERSION}"
else
    echo ""
    echo "ERROR: Build requires GNU toolchain version ${GCC_VERSION}."
    echo ""
    echo "  Run 'make distclean' to remove all build remnants then recompile to download the correct version."
    echo ""
    exit 1
fi
