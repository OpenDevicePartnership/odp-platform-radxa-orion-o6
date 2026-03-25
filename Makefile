# ODP Platform firmware build
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

SHELL := /bin/bash

# Defines used by this and all child makefiles
export ODP_PATH_BUILD_OUTPUT       ?= $(CURDIR)/Build
export ODP_PATH_BINS_OUTPUT        ?= $(ODP_PATH_BUILD_OUTPUT)/image-bootchain
export ODP_PATH_COMMON             ?= $(CURDIR)/common
export ODP_PATH_PACKAGE_TOOL       ?= $(CURDIR)/image-bootchain/cix_package-tool
export ODP_PATH_OEM_PRIVATE_KEY    ?= $(ODP_PATH_PACKAGE_TOOL)/Keys/oem_privatekey.pem
export ODP_PATH_PRE_COMPILED_BINS  ?= $(ODP_PATH_COMMON)/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/Firmwares
export ODP_PATH_GCC5_PREFIX        ?= $(ODP_PATH_COMMON)/tools/gnu-toolchain/bin/aarch64-none-elf-

# Build targets are all PHONY and rely on the module's makefiles to determine if a build is necessary
.PHONY: all pre-built uefi tee tf-a mem_config pm_config image-bootchain toolchain clean distclean test

# Targets for 'all' are order specific.  Toolchain first, copy the pre-built binaries, build the platform binaries,
# then final image stitch.
all: toolchain pre-built uefi tee tf-a mem_config pm_config image-bootchain

# Module targets to allow individual module builds
pre-built:
	$(MAKE) -C image-bootchain pre-built

uefi:
	$(MAKE) -C bin-uefi all

tee:
	$(MAKE) -C bin-tee all

tf-a:
	$(MAKE) -C bin-tf-a all

mem_config:
	$(MAKE) -C bin-mem_config all

pm_config:
	$(MAKE) -C bin-pm_config all

image-bootchain:
	$(MAKE) -C image-bootchain stitch-all

# Download the GNU toolchain if not present and verify the correct version is available.
toolchain:
	source $(ODP_PATH_COMMON)/tools/download-gnu-toolchain $(ODP_PATH_COMMON)/tools/gnu-toolchain

# Each module's make should not leave any remnant outside the 'Build' directory so a normal clean just removes './Build'
clean:
	rm -rf $(ODP_PATH_BUILD_OUTPUT)

# Distclean is a more thorough clean that targets modules that might have things like build tool remnants
distclean: clean
	$(MAKE) -C bin-uefi distclean
	rm -rf $(ODP_PATH_COMMON)/tools/gnu-toolchain

# Each module should have its own test target
test:
	$(MAKE) -C bin-uefi test
	cd $(ODP_PATH_COMMON)/tests/acpi && cargo test
