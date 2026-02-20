# ODP Platform firmware build system
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

# Defines typically provided by the parent makefile
BUILD_DIR                  ?= $(CURDIR)/Build
BINS_DIR                   ?= $(BUILD_DIR)
COMMON_DIR                 ?= $(CURDIR)/../common
export GCC5_AARCH64_PREFIX ?= $(CURDIR)/../tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-

# Full build
.PHONY: all
all:
	$(MAKE) -C arm-trusted-firmware-cix-odp \
		CROSS_COMPILE=$(GCC5_AARCH64_PREFIX) \
		MBEDTLS_DIR=../mbedtls \
		PLAT=sky1 \
		SPD=opteed \
		DEBUG=1 \
		BUILD_BASE=$(BUILD_DIR) \
		CIX_BOARD=evb \
		SMP=1 \
		TRUSTED_BOARD_BOOT=1 \
		ENABLE_FEAT_HCX=1 \
		ARM_ROTPK_LOCATION=devel_rsa \
		ROT_KEY=plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem \
		LDFLAGS="--no-warn-rwx-segments" \
		bl31
	mkdir -p $(BINS_DIR)
	cp -f $(BUILD_DIR)/sky1/debug/bl31.bin $(BINS_DIR)/
	cp -f $(BUILD_DIR)/sky1/debug/bl31/bl31.elf $(BINS_DIR)/

# Clean all build artifacts
.PHONY: clean
clean:
	rm -rf $(BINS_DIR)
	rm -rf $(BUILD_DIR)
