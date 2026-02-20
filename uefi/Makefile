# ODP Platform firmware build system
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

# Defines typically provided by the parent makefile
BUILD_DIR                  ?= $(CURDIR)/Build
BINS_DIR                   ?= $(BUILD_DIR)
COMMON_DIR                 ?= $(CURDIR)/../common
export GCC5_AARCH64_PREFIX ?= $(CURDIR)/../tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-

# Defines specific to this makefile
RUST_OUT_DIR               := $(BUILD_DIR)/Rust
SHELL                      := /bin/bash
export WORKSPACE           := $(CURDIR)
export IASL_PREFIX         := $(CURDIR)/tools/acpica/generate/unix/bin/
export PACKAGES_PATH       := $(CURDIR)/edk2:$(CURDIR)/platform:$(COMMON_DIR)/edk2-platforms-cix-odp:$(COMMON_DIR)/edk2-non-osi-cix-odp:$(RUST_OUT_DIR)

# Full build
.PHONY: all
all: PatinaDxeCore_ru

	$(MAKE) -C edk2/BaseTools
	$(MAKE) -C tools/acpica

	. edk2/edksetup.sh --reconfig && \
	build \
		-a AARCH64 \
		-t GCC5 \
		-p platform/O6.dsc \
		-b DEBUG \
		-D BOARD_NAME=evb \
		-D PATH_BUILD_OUTPUT=$(BUILD_DIR) \
		-D BUILD_DATE=$$(date +%VM%y%m%d%H%M%SN) \
		-D COMMIT_HASH=$$(git rev-parse --short=12 HEAD) \
		-D SMP_ENABLE=1 \
		-D ACPI_BOOT_ENABLE=1 \
		-D FASTBOOT_LOAD=disable \
		-D VARIABLE_TYPE=SPI \
		-D STANDARD_MM=TRUE \
		-D SYSTEM_LOADER=common

	mkdir -p $(BINS_DIR)
	cp $(BUILD_DIR)/DEBUG_GCC5/FV/SKY1_BL33_UEFI.fd $(BINS_DIR)/

# Build targets for each rust module
.PHONY: PatinaDxeCore_ru
PatinaDxeCore_ru:
	cd platform/Drivers/PatinaDxeCore_ru && cargo build --target-dir $(RUST_OUT_DIR)/Drivers/PatinaDxeCore_ru

# Clean all build artifacts
.PHONY: clean
clean:
	rm -rf $(BINS_DIR)
	rm -rf $(BUILD_DIR)
	$(MAKE) -C edk2/BaseTools clean
	$(MAKE) -C tools/acpica clean
