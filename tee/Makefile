OEM_PRIVATE_KEY ?= $(PATH_PACKAGE_TOOL)/Keys/oem_privatekey.pem
STMM_FD := $(BINS_DIR)/BL32_AP_EFI_STMM.fd

# Conditionally set CFG_STMM_PATH only if the firmware file exists
STMM_ARG := $(if $(wildcard $(STMM_FD)),CFG_STMM_PATH=$(STMM_FD),)

.PHONY: all clean

all:
	$(MAKE) -C op-tee-cix-odp \
		PLATFORM=cix \
		PLATFORM_FLAVOR=sky1 \
		$(STMM_ARG) \
		TA_SIGN_KEY=$(OEM_PRIVATE_KEY) \
		O=$(BUILD_OUTPUT) \
		ARCH=arm \
		CROSS_COMPILE64=$(GCC5_AARCH64_PREFIX) \
		CFG_ARM64_core=y \
		CFG_USER_TA_TARGETS=ta_arm64 \
		LDFLAGS="--no-warn-rwx-segments"
	mkdir -p $(BINS_DIR)
	cp -f $(BUILD_OUTPUT)/core/tee-raw.bin $(BINS_DIR)/

clean:
	rm -rf $(BUILD_OUTPUT)
	$(MAKE) -C op-tee-cix-odp clean O=$(BUILD_OUTPUT)
