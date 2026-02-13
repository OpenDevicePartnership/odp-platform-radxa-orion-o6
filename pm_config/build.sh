#!/usr/bin/env bash

echo "Building platform PM configuration"

cd "${PATH_CIX_BASE_PROJECT}/pm_config"
make || exit 1
mv ${PATH_CIX_BASE_PROJECT}/pm_config/csu_pm_config.bin "${PATH_BUILD_BOOTCHAIN_BINS}"

cd -
