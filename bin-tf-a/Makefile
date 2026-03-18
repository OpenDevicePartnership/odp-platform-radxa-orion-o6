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
	$(MAKE) -C arm-trusted-firmware-cix-odp \
		CROSS_COMPILE=$(GCC5_AARCH64_PREFIX) \
		MBEDTLS_DIR=../mbedtls \
		PLAT=sky1 \
		SPD=opteed \
		DEBUG=1 \
		BUILD_BASE=$(ODP_PATH_BUILD_OUTPUT)/tf-a \
		CIX_BOARD=evb \
		SMP=1 \
		TRUSTED_BOARD_BOOT=1 \
		ENABLE_FEAT_HCX=1 \
		ARM_ROTPK_LOCATION=devel_rsa \
		ROT_KEY=plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem \
		LDFLAGS="--no-warn-rwx-segments" \
		bl31
	cp -f $(ODP_PATH_BUILD_OUTPUT)/tf-a/sky1/debug/bl31.bin $(ODP_PATH_BINS_OUTPUT)/
	cp -f $(ODP_PATH_BUILD_OUTPUT)/tf-a/sky1/debug/bl31/bl31.elf $(ODP_PATH_BINS_OUTPUT)/
