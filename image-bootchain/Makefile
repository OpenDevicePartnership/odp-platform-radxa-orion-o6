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
.PHONY: stitch-all pre-built bootloader2 bootloader3 clean

stitch-all: bootloader2 bootloader3
	cd $(PATH_BINS) && \
	$(PATH_PACKAGE_TOOL)/cix_package_tool \
		-c $(PATH_COMMON)/spi_flash_config_all.json \
		-o $(ODP_PATH_BUILD_OUTPUT)/cix_flash_all.bin
	cd $(PATH_BINS) && \
	$(PATH_PACKAGE_TOOL)/cix_package_tool \
		-c $(PATH_COMMON)/spi_flash_config_ota.json \
		-O $(ODP_PATH_BUILD_OUTPUT)/cix_flash_ota.bin

pre-built:
	mkdir -p $(PATH_BINS)
	cp -f $(PATH_PACKAGE_TOOL)/Firmwares/* $(PATH_BINS)/
	cp -f $(PATH_PRE_COMPILED_BINS)/* $(PATH_BINS)/
	head -c 8192 /dev/zero | tr '\000' '\377' > $(PATH_BINS)/dummy.bin

bootloader2:
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

bootloader3:
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
	rm -f $(PATH_BINS)/bootloader2.img
	rm -f $(PATH_BINS)/bootloader3.img
	rm -rf $(ODP_PATH_BUILD_OUTPUT)
