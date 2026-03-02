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
PATH_OEM_PRIVATE_KEY       ?= $(CURDIR)/../tools/cix_package-tool/Keys/oem_privatekey.pem
BL32_AP_EFI_STMM_ARG       = CFG_STMM_PATH=$(PATH_BINS)/BL32_AP_EFI_STMM.fd

# Build Targets
.PHONY: all clean

all:
	$(MAKE) -C op-tee-cix-odp \
		PLATFORM=cix \
		PLATFORM_FLAVOR=sky1 \
		$(BL32_AP_EFI_STMM_ARG) \
		TA_SIGN_KEY=$(PATH_OEM_PRIVATE_KEY) \
		O=$(PATH_BUILD_OUTPUT) \
		ARCH=arm \
		CROSS_COMPILE64=$(GCC5_AARCH64_PREFIX) \
		CFG_ARM64_core=y \
		CFG_USER_TA_TARGETS=ta_arm64 \
		LDFLAGS="--no-warn-rwx-segments"
	mkdir -p $(PATH_BINS)
	cp -f $(PATH_BUILD_OUTPUT)/core/tee-raw.bin $(PATH_BINS)

clean:
	rm -f $(PATH_BINS)/tee-raw.bin
	rm -rf $(PATH_BUILD_OUTPUT)
