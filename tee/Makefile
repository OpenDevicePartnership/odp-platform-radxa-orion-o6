.PHONY: all

all:
	$(MAKE) -C op-tee-cix-odp \
		PLATFORM=cix \
		PLATFORM_FLAVOR=sky1 \
		CFG_STMM_PATH=$(PATH_BUILD_BOOTCHAIN_BINS)/BL32_AP_EFI_STMM.fd \
		O=$(PATH_BUILD_OUTPUT)/tee \
		ARCH=arm \
		CROSS_COMPILE64=$(GCC5_AARCH64_PREFIX) \
		CFG_ARM64_core=y \
		CFG_USER_TA_TARGETS=ta_arm64 \
		LDFLAGS="--no-warn-rwx-segments"
	cp -f $(PATH_BUILD_OUTPUT)/tee/core/tee-raw.bin $(PATH_BUILD_BOOTCHAIN_BINS)/
