
.PHONY: all

all:
	$(MAKE) -C op-tee-cix-odp \
		PLATFORM=cix \
		PLATFORM_FLAVOR=sky1 \
		CFG_STMM_PATH=$(BINS_DIR)/BL32_AP_EFI_STMM.fd \
		O=$(BUILD_OUTPUT) \
		ARCH=arm \
		CROSS_COMPILE64=$(GCC5_AARCH64_PREFIX) \
		CFG_ARM64_core=y \
		CFG_USER_TA_TARGETS=ta_arm64 \
		LDFLAGS="--no-warn-rwx-segments"
	mkdir -p $(BINS_DIR)
	cp -f $(BUILD_OUTPUT)/core/tee-raw.bin $(BINS_DIR)/
