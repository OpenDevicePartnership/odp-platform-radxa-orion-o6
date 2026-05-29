# Power management configuration build targets for the ODP Platform firmware
#
# SPDX-License-Identifier: MIT
#

# Guard: This makefile must be invoked from the root makefile
ifndef ODP_PATH_BUILD_OUTPUT
$(error This makefile must be invoked from the root makefile)
endif

# Build Targets
.PHONY: all

all:
	rm -rf $(ODP_PATH_BUILD_OUTPUT)/mod/pm_config
	cp -rf $(ODP_PATH_COMMON)/cix-edk2-platforms/Platform/Radxa/Orion/O6/pm_config/ $(ODP_PATH_BUILD_OUTPUT)/mod/pm_config/
	$(MAKE) -C $(ODP_PATH_BUILD_OUTPUT)/mod/pm_config

	mkdir -p $(ODP_PATH_BINS_OUTPUT)
	mv $(ODP_PATH_BUILD_OUTPUT)/mod/pm_config/csu_pm_config.bin $(ODP_PATH_BINS_OUTPUT)/

