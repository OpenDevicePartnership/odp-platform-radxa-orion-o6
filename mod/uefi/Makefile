# UEFI firmware build targets for the ODP Platform firmware
#
# SPDX-License-Identifier: MIT
#

# Guard: This makefile must be invoked from the root makefile
ifndef ODP_PATH_BUILD_OUTPUT
$(error This makefile must be invoked from the root makefile)
endif

# Defines specific to this makefile
RUST_OUT_DIR               := $(ODP_PATH_BUILD_OUTPUT)/mod/uefi/Rust
SHELL                      := /bin/bash
export WORKSPACE           := $(CURDIR)
export PACKAGES_PATH       := $(CURDIR)/edk2:$(CURDIR)/platform:$(ODP_PATH_COMMON)/edk2-platforms-cix-odp:$(ODP_PATH_COMMON)/edk2-non-osi-cix-odp:$(RUST_OUT_DIR)
export GCC5_AARCH64_PREFIX := $(ODP_PATH_GCC5_PREFIX)

# Build Targets
.PHONY: all PatinaDxeCore_ru distclean test

all: PatinaDxeCore_ru

	$(MAKE) -C edk2/BaseTools

	# TODO: Set MSFTThermal.asl feature flags enabled.
	#       This needs to be merged into the platform build process instead of a patch.
	@sed -i \
		-e 's/^\(#define MPTF_THERMAL_ENABLE\) .*/\1 1/' \
		-e 's/^\(#define MPTF_BATTERY_AND_PSU_ENABLE\) .*/\1 1/' \
		-e 's/^\(#define MPTF_POWERLIMIT_ENABLE\) .*/\1 1/' \
		-e 's/^\(#define MPTF_CUSTOMIZE_IO_SIGNALSS_ENABLE\) .*/\1 1/' \
		-e 's/^\(#define MPTF_POWER_TRACKER\) .*/\1 1/' \
		$(ODP_PATH_COMMON)/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/Drivers/AcpiPlatfomTables/MSFTThermal.asl

	. edk2/edksetup.sh --reconfig && \
	build \
		-a AARCH64 \
		-t GCC5 \
		-p platform/O6.dsc \
		-b DEBUG \
		-D BOARD_NAME=evb \
		-D PATH_BUILD_OUTPUT=$(ODP_PATH_BUILD_OUTPUT)/mod/uefi \
		-D BUILD_DATE=$$(date +%VM%y%m%d%H%M%SN) \
		-D COMMIT_HASH=$$(git rev-parse --short=12 HEAD) \
		-D SMP_ENABLE=1 \
		-D ACPI_BOOT_ENABLE=1 \
		-D FASTBOOT_LOAD=nvme \
		-D VARIABLE_TYPE=SPI \
		-D STANDARD_MM=TRUE \
		-D SYSTEM_LOADER=common

	mkdir -p $(ODP_PATH_BINS_OUTPUT)
	cp $(ODP_PATH_BUILD_OUTPUT)/mod/uefi/DEBUG_GCC5/FV/SKY1_BL33_UEFI.fd $(ODP_PATH_BINS_OUTPUT)/

# Build targets for each rust module, will verify formatting and check for warnings as errors
PatinaDxeCore_ru:
	cd platform/Drivers/PatinaDxeCore_ru && cargo fmt -- --check
	cd platform/Drivers/PatinaDxeCore_ru && cargo clippy --target-dir $(RUST_OUT_DIR)/Drivers/PatinaDxeCore_ru -- -D warnings
	cd platform/Drivers/PatinaDxeCore_ru && cargo build --target-dir $(RUST_OUT_DIR)/Drivers/PatinaDxeCore_ru

# Specific clean to remove remnants from tools that don't have a way to put remnants in the Build directory
distclean:
	$(MAKE) -C edk2/BaseTools clean
	git -C $(ODP_PATH_COMMON)/edk2-platforms-cix-odp checkout -- Platform/Radxa/Orion/O6/Drivers/AcpiPlatfomTables/MSFTThermal.asl 2>/dev/null || true

# Run unit tests on the host
test:
	cd platform/Drivers/PatinaDxeCore_ru && cargo test \
		--target x86_64-unknown-linux-gnu \
		-Z build-std=std,core,alloc,compiler_builtins,test \
		-Z build-std-features=compiler-builtins-mem
