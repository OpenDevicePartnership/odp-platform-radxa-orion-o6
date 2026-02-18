# PLATFORM NOTE:
# This build needs code that is provided in a monolithic delivery that can not be easily divided into
# a submodules that reside under this component.  Therefore, the COMMON_DISTRIBUTION_COMPONENTS path
# is being used to reach outside this component folder and into the common folder.
COMMON_DISTRIBUTION_COMPONENTS := $(CURDIR)/../common/

SHELL := /bin/bash
BUILD_OUTPUT_RU := $(BUILD_OUTPUT)/DEBUG_GCC5/RustModules

export WORKSPACE := $(CURDIR)
export PACKAGES_PATH := $(CURDIR)/edk2:$(CURDIR)/platform:$(COMMON_DISTRIBUTION_COMPONENTS)/edk2-platforms-cix-odp:$(COMMON_DISTRIBUTION_COMPONENTS)/edk2-non-osi-cix-odp:$(BUILD_OUTPUT_RU)
export IASL_PREFIX := $(CURDIR)/tools/acpica/generate/unix/bin/

.PHONY: all BuildTools RustModules

# Build entire UEFI
all: BuildTools RustModules TianocoreModules
	mkdir -p $(BINS_DIR)
	cp $(BUILD_OUTPUT)/DEBUG_GCC5/FV/SKY1_BL33_UEFI.fd $(BINS_DIR)/

# Tools that must be built before building UEFI
BuildTools:
	test -e edk2/BaseTools/Source/C/bin/VolInfo || $(MAKE) -C edk2/BaseTools
	test -e tools/acpica/generate/unix/bin/iasl || $(MAKE) -C tools/acpica

# All UEFI modules based on Tianocore EDK2
TianocoreModules: RustModules
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

# All Rust based modules to be linked into the final UEFI image
RUST_DRIVERS := \
	Drivers/PatinaDxeCore_ru

RustModules:
	mkdir -p $(BUILD_OUTPUT_RU)
	@for driver in $(RUST_DRIVERS); do \
		echo "Building $$driver" && \
		cd $(CURDIR)/platform/$$driver && \
		cargo build --target-dir $(BUILD_OUTPUT_RU)/$$driver; \
	done
