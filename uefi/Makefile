# PLATFORM NOTE:
# This build needs code that is provided in a monolithic delivery that can not be easily divided into
# a submodules that reside under this component.  Therefore, the COMMON_DISTRIBUTION_COMPONENTS path
# is being used to reach outside this component folder and into the common folder.
COMMON_DISTRIBUTION_COMPONENTS := $(CURDIR)/../common/

SHELL := /bin/bash

.PHONY: all

all:
	# Build BaseTools if needed
	test -e edk2/BaseTools/Source/C/bin/VolInfo || $(MAKE) -C edk2/BaseTools

	# Build IASL if needed
	test -e tools/acpica/generate/unix/bin/iasl || $(MAKE) -C tools/acpica

	# Build UEFI firmware
	export WORKSPACE=$(CURDIR) && \
	export PACKAGES_PATH=$(CURDIR)/edk2:$(CURDIR)/platform:$(COMMON_DISTRIBUTION_COMPONENTS)/edk2-platforms-cix-odp:$(COMMON_DISTRIBUTION_COMPONENTS)/edk2-non-osi-cix-odp && \
	export IASL_PREFIX=$(CURDIR)/tools/acpica/generate/unix/bin/ && \
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
	cp $(BUILD_OUTPUT)/DEBUG_GCC5/FV/SKY1_BL33_UEFI.fd $(BINS_DIR)/
