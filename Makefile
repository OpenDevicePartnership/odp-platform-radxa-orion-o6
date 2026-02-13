export TOOLCHAIN_WORKSPACE := $(CURDIR)
export GCC5_AARCH64_PREFIX := $(TOOLCHAIN_WORKSPACE)/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-
export PATH_PACKAGE_TOOL := $(TOOLCHAIN_WORKSPACE)/common/edk2-non-osi-cix-odp/Platform/CIX/Sky1/PackageTool
export PATH_CIX_BASE_PROJECT := $(TOOLCHAIN_WORKSPACE)/common/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6
export PATH_BUILD_OUTPUT := $(TOOLCHAIN_WORKSPACE)/Build
export PATH_BUILD_BOOTCHAIN_BINS := $(PATH_BUILD_OUTPUT)/Firmwares

OEM_PRIVATE_KEY := $(PATH_PACKAGE_TOOL)/Keys/oem_privatekey.pem

.PHONY: all prebuilt uefi tee tf-a mem_config pm_config bootloader2 bootloader3 flash clean

all: flash

#
# Copy prebuilt binaries and certificates to the output folder
#

prebuilt:
	mkdir -p $(PATH_BUILD_BOOTCHAIN_BINS)
	cp -f $(PATH_PACKAGE_TOOL)/Firmwares/* $(PATH_BUILD_BOOTCHAIN_BINS)/
	cp -f $(PATH_CIX_BASE_PROJECT)/Firmwares/* $(PATH_BUILD_BOOTCHAIN_BINS)/
	head -c 8192 /dev/zero | tr '\000' '\377' > $(PATH_BUILD_BOOTCHAIN_BINS)/dummy.bin

#
# Build individual components
#

uefi: prebuilt
	$(MAKE) -C uefi

tee: prebuilt
	$(MAKE) -C tee

tf-a: prebuilt
	$(MAKE) -C tf-a

mem_config: prebuilt
	$(MAKE) -C mem_config

pm_config: prebuilt
	$(MAKE) -C pm_config

#
# Generate bootloader2 image (tf-a + tee)
#

bootloader2: tf-a tee
	$(PATH_PACKAGE_TOOL)/cert_create_rsa \
		--key-alg rsa \
		--key-size 3072 \
		--hash-alg sha256 \
		--tfw-nvctr 31 \
		--rot-key $(OEM_PRIVATE_KEY) \
		--trusted-world-key $(OEM_PRIVATE_KEY) \
		--soc-fw-key $(OEM_PRIVATE_KEY) \
		--tos-fw-key $(OEM_PRIVATE_KEY) \
		--trusted-key-cert $(PATH_BUILD_BOOTCHAIN_BINS)/trusted_key.crt \
		--soc-fw-key-cert $(PATH_BUILD_BOOTCHAIN_BINS)/bl31_fw_key.crt \
		--tos-fw-key-cert $(PATH_BUILD_BOOTCHAIN_BINS)/tos_fw_key.crt \
		--soc-fw-cert $(PATH_BUILD_BOOTCHAIN_BINS)/bl31_fw_content.crt \
		--tos-fw-cert $(PATH_BUILD_BOOTCHAIN_BINS)/tos_fw_cert.crt \
		--soc-fw $(PATH_BUILD_BOOTCHAIN_BINS)/bl31.bin \
		--tos-fw $(PATH_BUILD_BOOTCHAIN_BINS)/tee-raw.bin
	$(PATH_PACKAGE_TOOL)/X86_64/fiptool create \
		--soc-fw $(PATH_BUILD_BOOTCHAIN_BINS)/bl31.bin \
		--tos-fw $(PATH_BUILD_BOOTCHAIN_BINS)/tee-raw.bin \
		--trusted-key-cert $(PATH_BUILD_BOOTCHAIN_BINS)/trusted_key.crt \
		--soc-fw-key-cert $(PATH_BUILD_BOOTCHAIN_BINS)/bl31_fw_key.crt \
		--tos-fw-key-cert $(PATH_BUILD_BOOTCHAIN_BINS)/tos_fw_key.crt \
		--soc-fw-cert $(PATH_BUILD_BOOTCHAIN_BINS)/bl31_fw_content.crt \
		--tos-fw-cert $(PATH_BUILD_BOOTCHAIN_BINS)/tos_fw_cert.crt \
		$(PATH_BUILD_BOOTCHAIN_BINS)/bootloader2.img

#
# Generate bootloader3 image (uefi)
#

bootloader3: uefi
	$(PATH_PACKAGE_TOOL)/cix_regen_trusted_key_cert \
		-p $(PATH_PACKAGE_TOOL)/Keys/oem_publickey.pem \
		-s $(OEM_PRIVATE_KEY) \
		-o $(PATH_BUILD_BOOTCHAIN_BINS)/trusted_key_no.crt
	$(PATH_PACKAGE_TOOL)/X86_64/cert_uefi_create_rsa \
		--key-alg rsa \
		--key-size 3072 \
		--hash-alg sha256 \
		-p \
		--ntfw-nvctr 223 \
		--nt-fw-cert $(PATH_BUILD_BOOTCHAIN_BINS)/nt_fw_cert.crt \
		--nt-fw-key-cert $(PATH_BUILD_BOOTCHAIN_BINS)/nt_fw_key.crt \
		--nt-fw-key $(OEM_PRIVATE_KEY) \
		--non-trusted-world-key $(OEM_PRIVATE_KEY) \
		--nt-fw $(PATH_BUILD_BOOTCHAIN_BINS)/SKY1_BL33_UEFI.fd
	$(PATH_PACKAGE_TOOL)/X86_64/fiptool create \
		--trusted-key-cert $(PATH_BUILD_BOOTCHAIN_BINS)/trusted_key_no.crt \
		--nt-fw-key-cert $(PATH_BUILD_BOOTCHAIN_BINS)/nt_fw_key.crt \
		--nt-fw-cert $(PATH_BUILD_BOOTCHAIN_BINS)/nt_fw_cert.crt \
		--nt-fw $(PATH_BUILD_BOOTCHAIN_BINS)/SKY1_BL33_UEFI.fd \
		$(PATH_BUILD_BOOTCHAIN_BINS)/bootloader3.img

#
# Generate final SPI flash images
#

flash: bootloader2 bootloader3 mem_config pm_config
	
	cd $(PATH_BUILD_BOOTCHAIN_BINS) && \
	$(PATH_PACKAGE_TOOL)/X86_64/cix_package_tool \
		-c $(TOOLCHAIN_WORKSPACE)/common/spi_flash_config_all.json \
		-o $(PATH_BUILD_OUTPUT)/cix_flash_all.bin
	
	cd $(PATH_BUILD_BOOTCHAIN_BINS) && \
	$(PATH_PACKAGE_TOOL)/X86_64/cix_package_tool \
		-c $(TOOLCHAIN_WORKSPACE)/common/spi_flash_config_ota.json \
		-O $(PATH_BUILD_OUTPUT)/cix_flash_ota.bin

clean:
	rm -rf $(PATH_BUILD_OUTPUT)
