# ODP Platform firmware build system
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0

# Defines used by child makefiles to control common directories
export PATH_BUILD_OUTPUT    ?= $(CURDIR)/Build
export PATH_BINS            ?= $(PATH_BUILD_OUTPUT)/Binaries
export PATH_COMMON          ?= $(CURDIR)/common
export PATH_OEM_PRIVATE_KEY ?= $(PATH_PACKAGE_TOOL)/Keys/oem_privatekey.pem
export GCC5_AARCH64_PREFIX  ?= $(CURDIR)/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-

# Defines specific to this makefile
PATH_PACKAGE_TOOL          := $(CURDIR)/tools/cix_package-tool
PATH_PRE_COMPILED_BINS     := $(PATH_COMMON)/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/Firmwares

# Build Targets
.PHONY: all prebuilt uefi tee tf-a mem_config pm_config bootloader2 bootloader3 clean test

all: prebuilt uefi tee tf-a mem_config pm_config bootloader2 bootloader3
	cd $(PATH_BINS) && \
	$(PATH_PACKAGE_TOOL)/cix_package_tool \
		-c $(PATH_COMMON)/spi_flash_config_all.json \
		-o $(PATH_BUILD_OUTPUT)/cix_flash_all.bin
	cd $(PATH_BINS) && \
	$(PATH_PACKAGE_TOOL)/cix_package_tool \
		-c $(PATH_COMMON)/spi_flash_config_ota.json \
		-O $(PATH_BUILD_OUTPUT)/cix_flash_ota.bin

prebuilt:
	mkdir -p $(PATH_BINS)
	cp -f $(PATH_PACKAGE_TOOL)/Firmwares/* $(PATH_BINS)/
	cp -f $(PATH_PRE_COMPILED_BINS)/* $(PATH_BINS)/
	head -c 8192 /dev/zero | tr '\000' '\377' > $(PATH_BINS)/dummy.bin

uefi: prebuilt
	$(MAKE) -C uefi PATH_BUILD_OUTPUT=$(PATH_BUILD_OUTPUT)/uefi

tee: prebuilt
	$(MAKE) -C tee PATH_BUILD_OUTPUT=$(PATH_BUILD_OUTPUT)/tee

tf-a: prebuilt
	$(MAKE) -C tf-a PATH_BUILD_OUTPUT=$(PATH_BUILD_OUTPUT)/tf-a

mem_config: prebuilt
	$(MAKE) -C mem_config PATH_BUILD_OUTPUT=$(PATH_BUILD_OUTPUT)/mem_config

pm_config: prebuilt
	$(MAKE) -C pm_config PATH_BUILD_OUTPUT=$(PATH_BUILD_OUTPUT)/pm_config

bootloader2: tf-a tee prebuilt
	$(PATH_PACKAGE_TOOL)/cert_create_rsa \
		--key-alg rsa \
		--key-size 3072 \
		--hash-alg sha256 \
		--tfw-nvctr 31 \
		--rot-key $(PATH_OEM_PRIVATE_KEY) \
		--trusted-world-key $(PATH_OEM_PRIVATE_KEY) \
		--soc-fw-key $(PATH_OEM_PRIVATE_KEY) \
		--tos-fw-key $(PATH_OEM_PRIVATE_KEY) \
		--trusted-key-cert $(PATH_BINS)/trusted_key.crt \
		--soc-fw-key-cert $(PATH_BINS)/bl31_fw_key.crt \
		--tos-fw-key-cert $(PATH_BINS)/tos_fw_key.crt \
		--soc-fw-cert $(PATH_BINS)/bl31_fw_content.crt \
		--tos-fw-cert $(PATH_BINS)/tos_fw_cert.crt \
		--soc-fw $(PATH_BINS)/bl31.bin \
		--tos-fw $(PATH_BINS)/tee-raw.bin
	$(PATH_PACKAGE_TOOL)/fiptool create \
		--soc-fw $(PATH_BINS)/bl31.bin \
		--tos-fw $(PATH_BINS)/tee-raw.bin \
		--trusted-key-cert $(PATH_BINS)/trusted_key.crt \
		--soc-fw-key-cert $(PATH_BINS)/bl31_fw_key.crt \
		--tos-fw-key-cert $(PATH_BINS)/tos_fw_key.crt \
		--soc-fw-cert $(PATH_BINS)/bl31_fw_content.crt \
		--tos-fw-cert $(PATH_BINS)/tos_fw_cert.crt \
		$(PATH_BINS)/bootloader2.img

bootloader3: uefi prebuilt
	$(PATH_PACKAGE_TOOL)/cix_regen_trusted_key_cert \
		-p $(PATH_PACKAGE_TOOL)/Keys/oem_publickey.pem \
		-s $(PATH_OEM_PRIVATE_KEY) \
		-o $(PATH_BINS)/trusted_key_no.crt
	$(PATH_PACKAGE_TOOL)/cert_uefi_create_rsa \
		--key-alg rsa \
		--key-size 3072 \
		--hash-alg sha256 \
		-p \
		--ntfw-nvctr 223 \
		--nt-fw-cert $(PATH_BINS)/nt_fw_cert.crt \
		--nt-fw-key-cert $(PATH_BINS)/nt_fw_key.crt \
		--nt-fw-key $(PATH_OEM_PRIVATE_KEY) \
		--non-trusted-world-key $(PATH_OEM_PRIVATE_KEY) \
		--nt-fw $(PATH_BINS)/SKY1_BL33_UEFI.fd
	$(PATH_PACKAGE_TOOL)/fiptool create \
		--trusted-key-cert $(PATH_BINS)/trusted_key_no.crt \
		--nt-fw-key-cert $(PATH_BINS)/nt_fw_key.crt \
		--nt-fw-cert $(PATH_BINS)/nt_fw_cert.crt \
		--nt-fw $(PATH_BINS)/SKY1_BL33_UEFI.fd \
		$(PATH_BINS)/bootloader3.img

clean:
	$(MAKE) -C uefi clean
	$(MAKE) -C tee clean
	$(MAKE) -C tf-a clean
	$(MAKE) -C mem_config clean
	$(MAKE) -C pm_config clean
	rm -rf $(PATH_BUILD_OUTPUT)

test:
	$(MAKE) -C uefi test
	cd tests/acpi && cargo test
