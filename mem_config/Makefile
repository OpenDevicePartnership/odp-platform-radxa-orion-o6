# ODP Platform firmware build system
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

# Defines typically provided by the parent makefile
ifdef BUILD_DIR
	BUILD_DIR              := $(BUILD_DIR)/$(notdir $(CURDIR))
else
	BUILD_DIR              := $(CURDIR)/Build
endif
BINS_DIR                   ?= $(BUILD_DIR)
COMMON_DIR                 ?= $(CURDIR)/../common
export GCC5_AARCH64_PREFIX ?= $(CURDIR)/../tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-

# Defines specific to this makefile
PLATFORM_CODE_DIR          := $(COMMON_DIR)/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/mem_config

# Full build
.PHONY: all
all:
	$(MAKE) -C $(PLATFORM_CODE_DIR)
	mkdir -p $(BINS_DIR)
	mv $(PLATFORM_CODE_DIR)/memory_config.bin $(BINS_DIR)/

# Clean all build artifacts
.PHONY: clean
clean:
	$(MAKE) -C $(PLATFORM_CODE_DIR) clean
	rm -rf $(BUILD_DIR)
	rm -f $(BINS_DIR)/memory_config.bin
