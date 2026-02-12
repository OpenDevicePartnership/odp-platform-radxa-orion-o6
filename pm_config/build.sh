#!/usr/bin/env bash

echo "Building platform PM configuration"

cd "${PATH_PROJECT}/pm_config"
make || exit 1
mv ${PATH_PROJECT}/pm_config/csu_pm_config.bin "$1"

cd -
