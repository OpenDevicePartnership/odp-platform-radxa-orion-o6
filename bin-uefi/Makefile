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

# Defines specific to this makefile
RUST_OUT_DIR               := $(ODP_PATH_BUILD_OUTPUT)/uefi/Rust
SHELL                      := /bin/bash
export WORKSPACE           := $(CURDIR)
export PACKAGES_PATH       := $(CURDIR)/edk2:$(CURDIR)/platform:$(ODP_PATH_COMMON)/edk2-platforms-cix-odp:$(ODP_PATH_COMMON)/edk2-non-osi-cix-odp:$(RUST_OUT_DIR)
export IASL_PREFIX         := $(CURDIR)/tools/acpica/generate/unix/bin/

# Build Targets
.PHONY: all PatinaDxeCore_ru clean test

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
		-D PATH_BUILD_OUTPUT=$(ODP_PATH_BUILD_OUTPUT)/uefi \
		-D BUILD_DATE=$$(date +%VM%y%m%d%H%M%SN) \
		-D COMMIT_HASH=$$(git rev-parse --short=12 HEAD) \
		-D SMP_ENABLE=1 \
		-D ACPI_BOOT_ENABLE=1 \
		-D FASTBOOT_LOAD=nvme \
		-D VARIABLE_TYPE=SPI \
		-D STANDARD_MM=TRUE \
		-D SYSTEM_LOADER=common
	cp $(ODP_PATH_BUILD_OUTPUT)/uefi/DEBUG_GCC5/FV/SKY1_BL33_UEFI.fd $(ODP_PATH_BINS_OUTPUT)/

# Build targets for each rust module, will verify formatting and check for warnings as errors
PatinaDxeCore_ru:
	cd platform/Drivers/PatinaDxeCore_ru && cargo fmt -- --check
	cd platform/Drivers/PatinaDxeCore_ru && cargo clippy --target-dir $(RUST_OUT_DIR)/Drivers/PatinaDxeCore_ru -- -D warnings
	cd platform/Drivers/PatinaDxeCore_ru && cargo build --target-dir $(RUST_OUT_DIR)/Drivers/PatinaDxeCore_ru

# Specific clean to remove remnants from tools that don't have a way to put remnants in the Build directory
distclean:
	$(MAKE) -C edk2/BaseTools clean
	$(MAKE) -C tools/acpica clean

# Run unit tests on the host
test:
	cd platform/Drivers/PatinaDxeCore_ru && cargo test \
		--target x86_64-unknown-linux-gnu \
		-Z build-std=std,core,alloc,compiler_builtins,test \
		-Z build-std-features=compiler-builtins-mem
