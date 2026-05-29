# Bootchain firmware build for the ODP Platform
#
# SPDX-License-Identifier: MIT
#

SHELL := /bin/bash

# Defines used by this and all child makefiles
export ODP_PATH_BUILD_OUTPUT       ?= $(CURDIR)/build
export ODP_PATH_BINS_OUTPUT        := $(ODP_PATH_BUILD_OUTPUT)/bootchain
export ODP_PATH_COMMON             := $(CURDIR)/../common
export ODP_PATH_PACKAGE_TOOL       := $(CURDIR)/cix_package-tool
export ODP_PATH_DOWNLOADS          := $(CURDIR)/downloads
export ODP_PATH_GCC5_PREFIX        := $(ODP_PATH_DOWNLOADS)/gnu-toolchain/bin/aarch64-none-elf-

# NOTE:  This key is being provided for signing demonstration only test binaries and should not be used for
# production signing.  Any production signing should use a secure key management process and private keys
# should not be stored in the repository.
export ODP_PATH_OEM_PRIVATE_KEY    := $(ODP_PATH_PACKAGE_TOOL)/Keys/oem_privatekey.pem

# Build targets are all PHONY and rely on the module's makefiles to determine if a build is necessary
.PHONY: all clean distclean test stitch-all pre-built bootloader2 bootloader3

# Ordering is specific: Toolchain first, copy the pre-built binaries, build binaries, then final image stitch.
all:
	$(ODP_PATH_COMMON)/tools/download-gnu-toolchain.sh
	$(MAKE) pre-built
	$(MAKE) -C modules/uefi all
	$(MAKE) -C modules/tee all
	$(MAKE) -C modules/tf-a all
	$(MAKE) -C modules/mem_config all
	$(MAKE) -C modules/pm_config all
	$(MAKE) -C modules/secure-services all
	$(MAKE) stitch-all

# Module's make should not leave any remnant outside the build directory so a normal clean just removes build/
clean:
	rm -rf $(ODP_PATH_BUILD_OUTPUT)

# Distclean is a more thorough clean to target modules that might have things like build tool remnants
distclean: clean
	$(MAKE) -C modules/uefi distclean

# A call into each module's test target
test:
	$(MAKE) -C modules/uefi test
	cd $(ODP_PATH_COMMON)/tests/acpi && cargo test

# Bootchain stitch and packaging targets
stitch-all: bootloader2 bootloader3
	cd $(ODP_PATH_BINS_OUTPUT) && \
	$(ODP_PATH_PACKAGE_TOOL)/cix_package_tool \
		-c $(ODP_PATH_COMMON)/spi_flash_config_all.json \
		-o $(ODP_PATH_BUILD_OUTPUT)/odp_orion_o6_bootchain.bin

pre-built:
	mkdir -p $(ODP_PATH_BINS_OUTPUT)
	cp -f $(ODP_PATH_PACKAGE_TOOL)/Firmwares/* $(ODP_PATH_BINS_OUTPUT)/
	cp -f $(ODP_PATH_COMMON)/cix-edk2-platforms/Platform/Radxa/Orion/O6/Firmwares/* $(ODP_PATH_BINS_OUTPUT)/
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
