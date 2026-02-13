.PHONY: all

all:
	$(MAKE) -C arm-trusted-firmware-cix-odp \
		CROSS_COMPILE=$(GCC5_AARCH64_PREFIX) \
		MBEDTLS_DIR=$(TOOLCHAIN_WORKSPACE)/tf-a/mbedtls \
		PLAT=sky1 \
		SPD=opteed \
		DEBUG=1 \
		BUILD_BASE=$(BUILD_OUTPUT)/tf-a \
		CIX_BOARD=evb \
		SMP=1 \
		TRUSTED_BOARD_BOOT=1 \
		ENABLE_FEAT_HCX=1 \
		ARM_ROTPK_LOCATION=devel_rsa \
		ROT_KEY=plat/arm/board/common/rotpk/arm_rotprivk_rsa.pem \
		LDFLAGS="--no-warn-rwx-segments" \
		bl31
	cp -f $(BUILD_OUTPUT)/tf-a/sky1/debug/bl31.bin $(BINS_DIR)/
	cp -f $(BUILD_OUTPUT)/tf-a/sky1/debug/bl31/bl31.elf $(BINS_DIR)/
