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
RUST_OUT_DIR               := $(PATH_BUILD_OUTPUT)/Rust
SHELL                      := /bin/bash
export WORKSPACE           := $(CURDIR)
export PACKAGES_PATH       := $(CURDIR)/edk2:$(CURDIR)/platform:$(PATH_COMMON)/edk2-platforms-cix-odp:$(PATH_COMMON)/edk2-non-osi-cix-odp:$(RUST_OUT_DIR)
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
		-D PATH_BUILD_OUTPUT=$(PATH_BUILD_OUTPUT) \
		-D BUILD_DATE=$$(date +%VM%y%m%d%H%M%SN) \
		-D COMMIT_HASH=$$(git rev-parse --short=12 HEAD) \
		-D SMP_ENABLE=1 \
		-D ACPI_BOOT_ENABLE=1 \
		-D FASTBOOT_LOAD=disable \
		-D VARIABLE_TYPE=SPI \
		-D STANDARD_MM=TRUE \
		-D SYSTEM_LOADER=common

	mkdir -p $(PATH_BINS)
	cp $(PATH_BUILD_OUTPUT)/DEBUG_GCC5/FV/SKY1_BL33_UEFI.fd $(PATH_BINS)/

# Build targets for each rust module, will auto format and check for warnings as errors
PatinaDxeCore_ru:
	cd platform/Drivers/PatinaDxeCore_ru && cargo fmt -- --check
	cd platform/Drivers/PatinaDxeCore_ru && cargo clippy --target-dir $(RUST_OUT_DIR)/Drivers/PatinaDxeCore_ru -- -D warnings
	cd platform/Drivers/PatinaDxeCore_ru && cargo build --target-dir $(RUST_OUT_DIR)/Drivers/PatinaDxeCore_ru

clean:
	rm -f $(PATH_BINS)/SKY1_BL33_UEFI.fd
	rm -rf $(PATH_BUILD_OUTPUT)
	$(MAKE) -C edk2/BaseTools clean
	$(MAKE) -C tools/acpica clean

# Run unit tests on the host
test:
	cd platform/Drivers/PatinaDxeCore_ru && cargo test \
		--target x86_64-unknown-linux-gnu \
		-Z build-std=std,core,alloc,compiler_builtins,test \
		-Z build-std-features=compiler-builtins-mem
