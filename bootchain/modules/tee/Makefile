# Trusted Execution Environment (OP-TEE) build targets for the ODP Platform firmware
#
# SPDX-License-Identifier: MIT
#

# Guard: This makefile must be invoked from the root makefile
ifndef ODP_PATH_BUILD_OUTPUT
$(error This makefile must be invoked from the root makefile)
endif

# Build Targets
.PHONY: all

all:
	$(MAKE) -C op-tee-cix-odp \
		PLATFORM=cix \
		PLATFORM_FLAVOR=sky1 \
		CFG_STMM_PATH=$(ODP_PATH_BINS_OUTPUT)/BL32_AP_EFI_STMM.fd \
		TA_SIGN_KEY=$(ODP_PATH_OEM_PRIVATE_KEY) \
		O=$(ODP_PATH_BUILD_OUTPUT)/mod/tee \
		ARCH=arm \
		CROSS_COMPILE64=$(ODP_PATH_GCC5_PREFIX) \
		CFG_ARM64_core=y \
		CFG_USER_TA_TARGETS=ta_arm64 \
		LDFLAGS="--no-warn-rwx-segments"

	mkdir -p $(ODP_PATH_BINS_OUTPUT)
	cp -f $(ODP_PATH_BUILD_OUTPUT)/mod/tee/core/tee-raw.bin $(ODP_PATH_BINS_OUTPUT)/

