# ODP Platform firmware build system
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

# Guard: this makefile must be invoked from the root makefile
ifndef ODP_PATH_BUILD_OUTPUT
$(error This makefile must be invoked from the root makefile)
endif

# Build Targets
.PHONY: all clean

all:
	rm -rf $(ODP_PATH_BUILD_OUTPUT)/bin-mem_config
	cp -rf $(ODP_PATH_COMMON)/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/mem_config/ $(ODP_PATH_BUILD_OUTPUT)/bin-mem_config/
	$(MAKE) -C $(ODP_PATH_BUILD_OUTPUT)/bin-mem_config
	mv $(ODP_PATH_BUILD_OUTPUT)/bin-mem_config/memory_config.bin $(ODP_PATH_BINS_OUTPUT)/

