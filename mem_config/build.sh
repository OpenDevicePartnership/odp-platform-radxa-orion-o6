#!/usr/bin/env bash

echo "Building platform memory configuration"

cd "${PATH_CIX_BASE_PROJECT}/mem_config"
make || exit 1
mv "${PATH_CIX_BASE_PROJECT}/mem_config/memory_config.bin" "${PATH_BUILD_BOOTCHAIN_BINS}"

cd -
