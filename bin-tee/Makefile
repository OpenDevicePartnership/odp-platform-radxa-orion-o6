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

# Build Targets
.PHONY: all clean

all:
	$(MAKE) -C op-tee-cix-odp \
		PLATFORM=cix \
		PLATFORM_FLAVOR=sky1 \
		CFG_STMM_PATH=$(PATH_BINS)/BL32_AP_EFI_STMM.fd \
		TA_SIGN_KEY=$(PATH_OEM_PRIVATE_KEY) \
		O=$(ODP_PATH_BUILD_OUTPUT)/bin-tee \
		ARCH=arm \
		CROSS_COMPILE64=$(GCC5_AARCH64_PREFIX) \
		CFG_ARM64_core=y \
		CFG_USER_TA_TARGETS=ta_arm64 \
		LDFLAGS="--no-warn-rwx-segments"
	cp -rf $(ODP_PATH_BUILD_OUTPUT)/bin-tee/core/tee-raw.bin $(PATH_BINS)

clean:
	rm -f $(PATH_BINS)/tee-raw.bin
	rm -rf $(ODP_PATH_BUILD_OUTPUT)/bin-tee
