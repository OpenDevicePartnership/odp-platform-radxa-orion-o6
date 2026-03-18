# ODP Platform firmware build system
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

# Defines used by this and all child makefiles
export ODP_PATH_BUILD_OUTPUT       ?= $(CURDIR)/Build
export ODP_PATH_BINS_OUTPUT        ?= $(ODP_PATH_BUILD_OUTPUT)/image-bootchain
export ODP_PATH_COMMON             ?= $(CURDIR)/common
export GCC5_AARCH64_PREFIX         ?= $(ODP_PATH_COMMON)/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-
export ODP_PATH_PACKAGE_TOOL       ?= $(CURDIR)/image-bootchain/cix_package-tool
export ODP_PATH_OEM_PRIVATE_KEY    ?= $(ODP_PATH_PACKAGE_TOOL)/Keys/oem_privatekey.pem
export ODP_PATH_PRE_COMPILED_BINS  ?= $(ODP_PATH_COMMON)/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/Firmwares

# Build targets are all PHONY and rely on the module's makefiles to determine if a build is necessary
.PHONY: all pre-built uefi tee tf-a mem_config pm_config image-bootchain clean test

# Targets for 'all' are order specific.  Pre-built first, binary builds next to over-write the pre-builts if they
# exist, then the final image stitching.
all: pre-built uefi tee tf-a mem_config pm_config image-bootchain

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

# Each module's make should not leave any remnant outside the 'Build' directory so a normal clean just removes './Build'
clean:
	rm -rf $(ODP_PATH_BUILD_OUTPUT)

# Distclean is a more thorough clean that targets modules that might have things like build tool remnants
distclean: clean
	$(MAKE) -C bin-uefi distclean

# Each module should have its own test target
test:
	$(MAKE) -C bin-uefi test
	cd common/tests/acpi && cargo test
