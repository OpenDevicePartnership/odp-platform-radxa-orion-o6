#!/usr/bin/env bash

echo "Building platform memory configuration"

cd "${PATH_PROJECT}/mem_config"
make || exit 1
mv "${PATH_PROJECT}/mem_config/memory_config.bin" "$1"

cd -
