# ODP Platform firmware build
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

SHELL := /bin/bash

# Defines used by this and all child makefiles
export ODP_PATH_BUILD_OUTPUT       ?= $(CURDIR)/build
export ODP_PATH_BINS_OUTPUT        := $(ODP_PATH_BUILD_OUTPUT)/postbuild/bootchain
export ODP_PATH_COMMON             := $(CURDIR)/common
export ODP_PATH_PACKAGE_TOOL       := $(CURDIR)/postbuild/bootchain/cix_package-tool
export ODP_PATH_OEM_PRIVATE_KEY    := $(ODP_PATH_PACKAGE_TOOL)/Keys/oem_privatekey.pem
export ODP_PATH_DOWNLOADS          := $(CURDIR)/downloads
export ODP_PATH_GCC5_PREFIX        := $(ODP_PATH_DOWNLOADS)/gnu-toolchain/bin/aarch64-none-elf-

# MSFTThermal.asl feature flags – set to 1 to enable the corresponding device nodes.
# These override the defaults (0) in the submodule file via build-time patching.
MPTF_THERMAL_ENABLE            ?= 1
MPTF_BATTERY_AND_PSU_ENABLE    ?= 1
MPTF_POWERLIMIT_ENABLE         ?= 1
MPTF_CUSTOMIZE_IO_SIGNALSS_ENABLE ?= 1
MPTF_POWER_TRACKER             ?= 1

MSFT_THERMAL_ASL := $(ODP_PATH_COMMON)/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/Drivers/AcpiPlatfomTables/MSFTThermal.asl

# Build targets are all PHONY and rely on the module's makefiles to determine if a build is necessary
.PHONY: all pre-built uefi tee tf-a mem_config pm_config bootchain clean distclean test patch-msft-mptf toolchain

# Targets for 'all' are order specific.  Toolchain first, copy the pre-built binaries, build the platform binaries,
# then final image stitch.
all: pre-built uefi tee tf-a mem_config pm_config bootchain secure-services

# Patch MSFTThermal.asl feature flags before UEFI build.
# The sed expressions replace the default #define values with the Make variable values.
# This modifies the submodule working tree; `make clean` restores the original.
patch-msft-mptf:
	@sed -i \
		-e 's/^\(#define MPTF_THERMAL_ENABLE\) .*/\1 $(MPTF_THERMAL_ENABLE)/' \
		-e 's/^\(#define MPTF_BATTERY_AND_PSU_ENABLE\) .*/\1 $(MPTF_BATTERY_AND_PSU_ENABLE)/' \
		-e 's/^\(#define MPTF_POWERLIMIT_ENABLE\) .*/\1 $(MPTF_POWERLIMIT_ENABLE)/' \
		-e 's/^\(#define MPTF_CUSTOMIZE_IO_SIGNALSS_ENABLE\) .*/\1 $(MPTF_CUSTOMIZE_IO_SIGNALSS_ENABLE)/' \
		-e 's/^\(#define MPTF_POWER_TRACKER\) .*/\1 $(MPTF_POWER_TRACKER)/' \
		$(MSFT_THERMAL_ASL)

# Module targets to allow individual module builds
pre-built:
	$(MAKE) -C postbuild/bootchain pre-built

uefi: toolchain patch-msft-mptf
	$(MAKE) -C mod/uefi all

tee: toolchain
	$(MAKE) -C mod/tee all

tf-a: toolchain
	$(MAKE) -C mod/tf-a all

mem_config:
	$(MAKE) -C mod/mem_config all

pm_config:
	$(MAKE) -C mod/pm_config all

secure-services:
	$(MAKE) -C mod/secure-services all

bootchain:
	$(MAKE) -C postbuild/bootchain stitch-all

# Download the GNU toolchain if not present and verify the correct version is available.
toolchain:
	$(ODP_PATH_COMMON)/tools/download-gnu-toolchain.sh

# Each module's make should not leave any remnant outside the 'build' directory so a normal clean just removes
# './build' plus any patches to submodule files.
clean:
	git -C $(ODP_PATH_COMMON)/edk2-platforms-cix-odp checkout -- \
		Platform/Radxa/Orion/O6/Drivers/AcpiPlatfomTables/MSFTThermal.asl 2>/dev/null || true
	rm -rf $(ODP_PATH_BUILD_OUTPUT)

# Distclean is a more thorough clean to target modules that might have things like build tool remnants and also
# removes the './downloads' directory.
distclean: clean
	$(MAKE) -C mod/uefi distclean
	rm -rf $(ODP_PATH_DOWNLOADS)

# Each module should have its own test target
test:
	$(MAKE) -C mod/uefi test
	cd $(ODP_PATH_COMMON)/tests/acpi && cargo test
