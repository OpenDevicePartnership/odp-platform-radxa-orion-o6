# ODP Platform firmware build system
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

# Defines typically provided by the parent makefile
ifdef BUILD_DIR
	BUILD_DIR              := $(BUILD_DIR)/$(notdir $(CURDIR))
else
	BUILD_DIR              := $(CURDIR)/Build
endif
BINS_DIR                   ?= $(BUILD_DIR)
COMMON_DIR                 ?= $(CURDIR)/../common
export GCC5_AARCH64_PREFIX ?= $(CURDIR)/../tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-

# Full build
.PHONY: all
all: BL32_AP_EFI_STMM
	$(MAKE) -C op-tee-cix-odp \
		PLATFORM=cix \
		PLATFORM_FLAVOR=sky1 \
		CFG_STMM_PATH=$(BINS_DIR)/BL32_AP_EFI_STMM.fd \
		O=$(BUILD_DIR) \
		ARCH=arm \
		CROSS_COMPILE64=$(GCC5_AARCH64_PREFIX) \
		CFG_ARM64_core=y \
		CFG_USER_TA_TARGETS=ta_arm64 \
		LDFLAGS="--no-warn-rwx-segments"
	mkdir -p $(BINS_DIR)
	cp -f $(BUILD_DIR)/core/tee-raw.bin $(BINS_DIR)/

.PHONY: BL32_AP_EFI_STMM
BL32_AP_EFI_STMM:
	mkdir -p $(BINS_DIR)
	@if [ ! -f "$(BINS_DIR)/BL32_AP_EFI_STMM.fd" ]; then \
		echo "ERROR: Place the BL32_AP_EFI_STMM firmware .fd file in the $(BINS_DIR) directory then run 'make' again."; \
		exit 1; \
	fi

# Clean all build artifacts
.PHONY: clean
clean:
	rm -f $(BINS_DIR)/tee-raw.bin
	rm -drf $(BUILD_DIR)
