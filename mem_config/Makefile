# ODP Platform firmware build system
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

# Defines typically provided by the parent makefile
PATH_BUILD_OUTPUT          ?= $(CURDIR)/Build
PATH_BINS                  ?= $(PATH_BUILD_OUTPUT)
PATH_COMMON                ?= $(CURDIR)/../common
export GCC5_AARCH64_PREFIX ?= $(CURDIR)/../tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-

# Defines specific to this makefile
PLATFORM_CODE_DIR          := $(PATH_COMMON)/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/mem_config

# Build Targets
.PHONY: all clean

all:
	$(MAKE) -C $(PLATFORM_CODE_DIR)
	mkdir -p $(PATH_BINS)
	mv $(PLATFORM_CODE_DIR)/memory_config.bin $(PATH_BINS)/

clean:
	$(MAKE) -C $(PLATFORM_CODE_DIR) clean
	rm -f $(PATH_BINS)/memory_config.bin
	rm -rf $(PATH_BUILD_OUTPUT)
