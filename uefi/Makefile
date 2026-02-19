# PLATFORM NOTE:
# This build needs code that is provided in a monolithic delivery that can not be easily divided into
# a submodules that reside under this component.  Therefore, the 'COMMON' path is being used to reach
# outside this component folder and into the common folder.

SHELL        := /bin/bash
COMMON       := $(CURDIR)/../common
BUILD_OUTPUT ?= $(CURDIR)/Build
BINS_DIR     ?= $(CURDIR)/Build
RUST_OUT     := $(BUILD_OUTPUT)/DEBUG_Rust

export GCC5_AARCH64_PREFIX := $(CURDIR)/../tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-
export WORKSPACE           := $(CURDIR)
export PACKAGES_PATH       := $(CURDIR)/edk2:$(CURDIR)/platform:$(COMMON)/edk2-platforms-cix-odp:$(COMMON)/edk2-non-osi-cix-odp:$(RUST_OUT)
export IASL_PREFIX         := $(CURDIR)/tools/acpica/generate/unix/bin/

.PHONY: all PatinaDxeCore_ru

# The UEFI build process
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
		-D PATH_BUILD_OUTPUT=$(BUILD_OUTPUT) \
		-D BUILD_DATE=$$(date +%VM%y%m%d%H%M%SN) \
		-D COMMIT_HASH=$$(git rev-parse --short=12 HEAD) \
		-D SMP_ENABLE=1 \
		-D ACPI_BOOT_ENABLE=1 \
		-D FASTBOOT_LOAD=disable \
		-D VARIABLE_TYPE=SPI \
		-D STANDARD_MM=TRUE \
		-D SYSTEM_LOADER=common

	mkdir -p $(BINS_DIR)
	cp $(BUILD_OUTPUT)/DEBUG_GCC5/FV/SKY1_BL33_UEFI.fd $(BINS_DIR)/

# Build targets for each rust module
PatinaDxeCore_ru:
	cd platform/Drivers/PatinaDxeCore_ru && cargo build --target-dir $(RUST_OUT)/Drivers/PatinaDxeCore_ru

# Clean target
clean:
	rm -rf $(BUILD_OUTPUT)
