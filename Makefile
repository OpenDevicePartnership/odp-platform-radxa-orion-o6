# ODP Platform firmware build system
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

# Defines used by this and all child makefiles
export ODP_PATH_BUILD_OUTPUT    ?= $(CURDIR)/Build
export PATH_BINS                ?= $(ODP_PATH_BUILD_OUTPUT)/image-bootchain
export PATH_COMMON              ?= $(CURDIR)/common
export GCC5_AARCH64_PREFIX      ?= $(PATH_COMMON)/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-
export PATH_PACKAGE_TOOL        ?= $(CURDIR)/image-bootchain/cix_package-tool
export PATH_OEM_PRIVATE_KEY     ?= $(PATH_PACKAGE_TOOL)/Keys/oem_privatekey.pem
export PATH_PRE_COMPILED_BINS	?= $(PATH_COMMON)/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/Firmwares

# Build Targets
.PHONY: all pre-built uefi tee tf-a mem_config pm_config image-bootchain clean test

# Targets for all are order specific.  Pre-built first, binary builds next, then final image stitching last.
all: pre-built uefi tee tf-a mem_config pm_config image-bootchain

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

clean:
	$(MAKE) -C bin-uefi clean
	$(MAKE) -C bin-tee clean
	$(MAKE) -C bin-tf-a clean
	$(MAKE) -C bin-mem_config clean
	$(MAKE) -C bin-pm_config clean
	$(MAKE) -C image-bootchain clean
	rm -rf $(ODP_PATH_BUILD_OUTPUT)

test:
	$(MAKE) -C bin-uefi test
	cd common/tests/acpi && cargo test
