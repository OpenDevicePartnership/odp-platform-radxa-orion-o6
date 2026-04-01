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
.PHONY: stitch-all pre-built bootloader2 bootloader3

stitch-all: bootloader2 bootloader3
	cd $(ODP_PATH_BINS_OUTPUT) && \
	$(ODP_PATH_PACKAGE_TOOL)/cix_package_tool \
		-c $(ODP_PATH_COMMON)/spi_flash_config_all.json \
		-o $(ODP_PATH_BUILD_OUTPUT)/cix_flash_all.bin
	cd $(ODP_PATH_BINS_OUTPUT) && \
	$(ODP_PATH_PACKAGE_TOOL)/cix_package_tool \
		-c $(ODP_PATH_COMMON)/spi_flash_config_ota.json \
		-O $(ODP_PATH_BUILD_OUTPUT)/cix_flash_ota.bin

pre-built:
	mkdir -p $(ODP_PATH_BINS_OUTPUT)
	cp -f $(ODP_PATH_PACKAGE_TOOL)/Firmwares/* $(ODP_PATH_BINS_OUTPUT)/
	cp -f $(ODP_PATH_COMMON)/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/Firmwares/* $(ODP_PATH_BINS_OUTPUT)/
	head -c 8192 /dev/zero | tr '\000' '\377' > $(ODP_PATH_BINS_OUTPUT)/dummy.bin

bootloader2:
	$(ODP_PATH_PACKAGE_TOOL)/cert_create_rsa \
		--key-alg rsa \
		--key-size 3072 \
		--hash-alg sha256 \
		--tfw-nvctr 31 \
		--rot-key $(ODP_PATH_OEM_PRIVATE_KEY) \
		--trusted-world-key $(ODP_PATH_OEM_PRIVATE_KEY) \
		--soc-fw-key $(ODP_PATH_OEM_PRIVATE_KEY) \
		--tos-fw-key $(ODP_PATH_OEM_PRIVATE_KEY) \
		--trusted-key-cert $(ODP_PATH_BINS_OUTPUT)/trusted_key.crt \
		--soc-fw-key-cert $(ODP_PATH_BINS_OUTPUT)/bl31_fw_key.crt \
		--tos-fw-key-cert $(ODP_PATH_BINS_OUTPUT)/tos_fw_key.crt \
		--soc-fw-cert $(ODP_PATH_BINS_OUTPUT)/bl31_fw_content.crt \
		--tos-fw-cert $(ODP_PATH_BINS_OUTPUT)/tos_fw_cert.crt \
		--soc-fw $(ODP_PATH_BINS_OUTPUT)/bl31.bin \
		--tos-fw $(ODP_PATH_BINS_OUTPUT)/tee-raw.bin
	$(ODP_PATH_PACKAGE_TOOL)/fiptool create \
		--soc-fw $(ODP_PATH_BINS_OUTPUT)/bl31.bin \
		--tos-fw $(ODP_PATH_BINS_OUTPUT)/tee-raw.bin \
		--trusted-key-cert $(ODP_PATH_BINS_OUTPUT)/trusted_key.crt \
		--soc-fw-key-cert $(ODP_PATH_BINS_OUTPUT)/bl31_fw_key.crt \
		--tos-fw-key-cert $(ODP_PATH_BINS_OUTPUT)/tos_fw_key.crt \
		--soc-fw-cert $(ODP_PATH_BINS_OUTPUT)/bl31_fw_content.crt \
		--tos-fw-cert $(ODP_PATH_BINS_OUTPUT)/tos_fw_cert.crt \
		$(ODP_PATH_BINS_OUTPUT)/bootloader2.img

bootloader3:
	$(ODP_PATH_PACKAGE_TOOL)/cix_regen_trusted_key_cert \
		-p $(ODP_PATH_PACKAGE_TOOL)/Keys/oem_publickey.pem \
		-s $(ODP_PATH_OEM_PRIVATE_KEY) \
		-o $(ODP_PATH_BINS_OUTPUT)/trusted_key_no.crt
	$(ODP_PATH_PACKAGE_TOOL)/cert_uefi_create_rsa \
		--key-alg rsa \
		--key-size 3072 \
		--hash-alg sha256 \
		-p \
		--ntfw-nvctr 223 \
		--nt-fw-cert $(ODP_PATH_BINS_OUTPUT)/nt_fw_cert.crt \
		--nt-fw-key-cert $(ODP_PATH_BINS_OUTPUT)/nt_fw_key.crt \
		--nt-fw-key $(ODP_PATH_OEM_PRIVATE_KEY) \
		--non-trusted-world-key $(ODP_PATH_OEM_PRIVATE_KEY) \
		--nt-fw $(ODP_PATH_BINS_OUTPUT)/SKY1_BL33_UEFI.fd
	$(ODP_PATH_PACKAGE_TOOL)/fiptool create \
		--trusted-key-cert $(ODP_PATH_BINS_OUTPUT)/trusted_key_no.crt \
		--nt-fw-key-cert $(ODP_PATH_BINS_OUTPUT)/nt_fw_key.crt \
		--nt-fw-cert $(ODP_PATH_BINS_OUTPUT)/nt_fw_cert.crt \
		--nt-fw $(ODP_PATH_BINS_OUTPUT)/SKY1_BL33_UEFI.fd \
		$(ODP_PATH_BINS_OUTPUT)/bootloader3.img
