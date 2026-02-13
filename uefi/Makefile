SHELL := /bin/bash

.PHONY: all

all:
	# Build BaseTools if needed
	test -e edk2/BaseTools/Source/C/bin/VolInfo || $(MAKE) -C edk2/BaseTools

	# Build IASL if needed
	test -e $(TOOLCHAIN_WORKSPACE)/uefi/tools/acpica/generate/unix/bin/iasl || $(MAKE) -C $(TOOLCHAIN_WORKSPACE)/uefi/tools/acpica

	# Build UEFI firmware
	export WORKSPACE=$(CURDIR) && \
	export PACKAGES_PATH=$(CURDIR)/edk2:$(CURDIR)/platform:$(TOOLCHAIN_WORKSPACE)/common/edk2-platforms-cix-odp:$(TOOLCHAIN_WORKSPACE)/common/edk2-non-osi-cix-odp && \
	export IASL_PREFIX=$(TOOLCHAIN_WORKSPACE)/uefi/tools/acpica/generate/unix/bin/ && \
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
	cp $(PATH_BUILD_OUTPUT)/uefi/DEBUG_GCC5/FV/SKY1_BL33_UEFI.fd $(BINS_DIR)/
