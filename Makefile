# ODP Platform firmware build system
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

# Defines used by child makefiles to control common directories
export BUILD_DIR           ?= $(CURDIR)/Build
export BINS_DIR            ?= $(BUILD_DIR)/Binaries
export COMMON_DIR          ?= $(CURDIR)/common
export GCC5_AARCH64_PREFIX ?= $(CURDIR)/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-

# Defines specific to this makefile
PATH_PACKAGE_TOOL          := $(COMMON_DIR)/edk2-non-osi-cix-odp/Platform/CIX/Sky1/PackageTool
OEM_PRIVATE_KEY            := $(PATH_PACKAGE_TOOL)/Keys/oem_privatekey.pem
PRE_COMPILED_BINS_DIR      := $(COMMON_DIR)/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/Firmwares

# Full bootchain build
.PHONY: all
all: prebuilt uefi tee tf-a mem_config pm_config bootloader2 bootloader3
	cd $(BINS_DIR) && $(PATH_PACKAGE_TOOL)/X86_64/cix_package_tool -c $(COMMON_DIR)/spi_flash_config_all.json -o $(BUILD_DIR)/cix_flash_all.bin
	cd $(BINS_DIR) && $(PATH_PACKAGE_TOOL)/X86_64/cix_package_tool -c $(COMMON_DIR)/spi_flash_config_ota.json -O $(BUILD_DIR)/cix_flash_ota.bin

# Copies prebuilt binaries to the build output directory
.PHONY: prebuilt
prebuilt:
	mkdir -p $(BINS_DIR)
	cp -f $(PATH_PACKAGE_TOOL)/Firmwares/* $(BINS_DIR)/
	cp -f $(PRE_COMPILED_BINS_DIR)/* $(BINS_DIR)/
	head -c 8192 /dev/zero | tr '\000' '\377' > $(BINS_DIR)/dummy.bin

# Build the uefi component
.PHONY: uefi
uefi: prebuilt
	$(MAKE) -C uefi

# Build the tee component
.PHONY: tee
tee: prebuilt
	$(MAKE) -C tee

# Build the tf-a component
.PHONY: tf-a
tf-a: prebuilt
	$(MAKE) -C tf-a

# Build the mem_config component
.PHONY: mem_config
mem_config: prebuilt
	$(MAKE) -C mem_config

# Build the pm_config component
.PHONY: pm_config
pm_config: prebuilt
	$(MAKE) -C pm_config

# Combine and sign the secure partitions
.PHONY: bootloader2
bootloader2: tf-a tee prebuilt
	$(PATH_PACKAGE_TOOL)/cert_create_rsa \
		--key-alg rsa \
		--key-size 3072 \
		--hash-alg sha256 \
		--tfw-nvctr 31 \
		--rot-key $(OEM_PRIVATE_KEY) \
		--trusted-world-key $(OEM_PRIVATE_KEY) \
		--soc-fw-key $(OEM_PRIVATE_KEY) \
		--tos-fw-key $(OEM_PRIVATE_KEY) \
		--trusted-key-cert $(BINS_DIR)/trusted_key.crt \
		--soc-fw-key-cert $(BINS_DIR)/bl31_fw_key.crt \
		--tos-fw-key-cert $(BINS_DIR)/tos_fw_key.crt \
		--soc-fw-cert $(BINS_DIR)/bl31_fw_content.crt \
		--tos-fw-cert $(BINS_DIR)/tos_fw_cert.crt \
		--soc-fw $(BINS_DIR)/bl31.bin \
		--tos-fw $(BINS_DIR)/tee-raw.bin
	$(PATH_PACKAGE_TOOL)/X86_64/fiptool create \
		--soc-fw $(BINS_DIR)/bl31.bin \
		--tos-fw $(BINS_DIR)/tee-raw.bin \
		--trusted-key-cert $(BINS_DIR)/trusted_key.crt \
		--soc-fw-key-cert $(BINS_DIR)/bl31_fw_key.crt \
		--tos-fw-key-cert $(BINS_DIR)/tos_fw_key.crt \
		--soc-fw-cert $(BINS_DIR)/bl31_fw_content.crt \
		--tos-fw-cert $(BINS_DIR)/tos_fw_cert.crt \
		$(BINS_DIR)/bootloader2.img

# Sign the UEFI
.PHONY: bootloader3
bootloader3: uefi prebuilt
	$(PATH_PACKAGE_TOOL)/cix_regen_trusted_key_cert \
		-p $(PATH_PACKAGE_TOOL)/Keys/oem_publickey.pem \
		-s $(OEM_PRIVATE_KEY) \
		-o $(BINS_DIR)/trusted_key_no.crt
	$(PATH_PACKAGE_TOOL)/X86_64/cert_uefi_create_rsa \
		--key-alg rsa \
		--key-size 3072 \
		--hash-alg sha256 \
		-p \
		--ntfw-nvctr 223 \
		--nt-fw-cert $(BINS_DIR)/nt_fw_cert.crt \
		--nt-fw-key-cert $(BINS_DIR)/nt_fw_key.crt \
		--nt-fw-key $(OEM_PRIVATE_KEY) \
		--non-trusted-world-key $(OEM_PRIVATE_KEY) \
		--nt-fw $(BINS_DIR)/SKY1_BL33_UEFI.fd
	$(PATH_PACKAGE_TOOL)/X86_64/fiptool create \
		--trusted-key-cert $(BINS_DIR)/trusted_key_no.crt \
		--nt-fw-key-cert $(BINS_DIR)/nt_fw_key.crt \
		--nt-fw-cert $(BINS_DIR)/nt_fw_cert.crt \
		--nt-fw $(BINS_DIR)/SKY1_BL33_UEFI.fd \
		$(BINS_DIR)/bootloader3.img

# Clean all build artifacts
.PHONY: clean
clean:
	$(MAKE) -C uefi clean
	$(MAKE) -C tee clean
	$(MAKE) -C tf-a clean
	$(MAKE) -C mem_config clean
	$(MAKE) -C pm_config clean
	rm -rf $(BUILD_DIR)
