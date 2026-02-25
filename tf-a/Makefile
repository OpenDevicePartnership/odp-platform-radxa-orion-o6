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

# Build Targets
.PHONY: all clean

all:
	$(MAKE) -C arm-trusted-firmware-cix-odp \
		CROSS_COMPILE=$(GCC5_AARCH64_PREFIX) \
		MBEDTLS_DIR=../mbedtls \
		PLAT=sky1 \
		SPD=opteed \
		DEBUG=1 \
		BUILD_BASE=$(PATH_BUILD_OUTPUT) \
		CIX_BOARD=evb \
		SMP=1 \
		TRUSTED_BOARD_BOOT=1 \
		ENABLE_FEAT_HCX=1 \
		ARM_ROTPK_LOCATION=devel_rsa \
		ROT_KEY=plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem \
		LDFLAGS="--no-warn-rwx-segments" \
		bl31
	mkdir -p $(PATH_BINS)
	cp -f $(PATH_BUILD_OUTPUT)/sky1/debug/bl31.bin $(PATH_BINS)/
	cp -f $(PATH_BUILD_OUTPUT)/sky1/debug/bl31/bl31.elf $(PATH_BINS)/

clean:
	rm -f $(PATH_BINS)/bl31.bin
	rm -f $(PATH_BINS)/bl31.elf
	rm -rf $(PATH_BUILD_OUTPUT)
