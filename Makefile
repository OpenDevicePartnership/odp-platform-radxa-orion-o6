# PLATFORM NOTE:
# This build needs code that is provided in a monolithic delivery that can not be easily divided into
# submodules that reside under individual component folders.  Therefore, the PATH_PACKAGE_TOOL and
# PATH_CIX_REFERENCE_PROJECT environment variables will be used in other makefiles to reach outside
# the component folders and into the common folder.
export PATH_PACKAGE_TOOL := $(CURDIR)/common/edk2-non-osi-cix-odp/Platform/CIX/Sky1/PackageTool
export PATH_CIX_REFERENCE_PROJECT := $(CURDIR)/common/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6

export GCC5_AARCH64_PREFIX := $(CURDIR)/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-
BUILD_OUTPUT := $(CURDIR)/Build
BINS := $(BUILD_OUTPUT)/Firmwares
OEM_PRIVATE_KEY := $(PATH_PACKAGE_TOOL)/Keys/oem_privatekey.pem

.PHONY: all prebuilt uefi tee tf-a mem_config pm_config bootloader2 bootloader3 flash clean

all: prebuilt uefi tee tf-a mem_config pm_config bootloader2 bootloader3
	cd $(BINS) && \
	$(PATH_PACKAGE_TOOL)/X86_64/cix_package_tool \
		-c $(CURDIR)/common/spi_flash_config_all.json \
		-o $(BUILD_OUTPUT)/cix_flash_all.bin
	cd $(BINS) && \
	$(PATH_PACKAGE_TOOL)/X86_64/cix_package_tool \
		-c $(CURDIR)/common/spi_flash_config_ota.json \
		-O $(BUILD_OUTPUT)/cix_flash_ota.bin

prebuilt:
	mkdir -p $(BINS)
	cp -f $(PATH_PACKAGE_TOOL)/Firmwares/* $(BINS)/
	cp -f $(PATH_CIX_REFERENCE_PROJECT)/Firmwares/* $(BINS)/
	head -c 8192 /dev/zero | tr '\000' '\377' > $(BINS)/dummy.bin

uefi:
	$(MAKE) -C uefi BINS_DIR=$(BINS) BUILD_OUTPUT=$(BUILD_OUTPUT)/uefi

tee: prebuilt
	$(MAKE) -C tee BINS_DIR=$(BINS) BUILD_OUTPUT=$(BUILD_OUTPUT)/tee

tf-a:
	$(MAKE) -C tf-a BINS_DIR=$(BINS) BUILD_OUTPUT=$(BUILD_OUTPUT)/tf-a

mem_config:
	$(MAKE) -C mem_config BINS_DIR=$(BINS)

pm_config:
	$(MAKE) -C pm_config BINS_DIR=$(BINS)

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
		--trusted-key-cert $(BINS)/trusted_key.crt \
		--soc-fw-key-cert $(BINS)/bl31_fw_key.crt \
		--tos-fw-key-cert $(BINS)/tos_fw_key.crt \
		--soc-fw-cert $(BINS)/bl31_fw_content.crt \
		--tos-fw-cert $(BINS)/tos_fw_cert.crt \
		--soc-fw $(BINS)/bl31.bin \
		--tos-fw $(BINS)/tee-raw.bin
	$(PATH_PACKAGE_TOOL)/X86_64/fiptool create \
		--soc-fw $(BINS)/bl31.bin \
		--tos-fw $(BINS)/tee-raw.bin \
		--trusted-key-cert $(BINS)/trusted_key.crt \
		--soc-fw-key-cert $(BINS)/bl31_fw_key.crt \
		--tos-fw-key-cert $(BINS)/tos_fw_key.crt \
		--soc-fw-cert $(BINS)/bl31_fw_content.crt \
		--tos-fw-cert $(BINS)/tos_fw_cert.crt \
		$(BINS)/bootloader2.img

bootloader3: uefi prebuilt
	$(PATH_PACKAGE_TOOL)/cix_regen_trusted_key_cert \
		-p $(PATH_PACKAGE_TOOL)/Keys/oem_publickey.pem \
		-s $(OEM_PRIVATE_KEY) \
		-o $(BINS)/trusted_key_no.crt
	$(PATH_PACKAGE_TOOL)/X86_64/cert_uefi_create_rsa \
		--key-alg rsa \
		--key-size 3072 \
		--hash-alg sha256 \
		-p \
		--ntfw-nvctr 223 \
		--nt-fw-cert $(BINS)/nt_fw_cert.crt \
		--nt-fw-key-cert $(BINS)/nt_fw_key.crt \
		--nt-fw-key $(OEM_PRIVATE_KEY) \
		--non-trusted-world-key $(OEM_PRIVATE_KEY) \
		--nt-fw $(BINS)/SKY1_BL33_UEFI.fd
	$(PATH_PACKAGE_TOOL)/X86_64/fiptool create \
		--trusted-key-cert $(BINS)/trusted_key_no.crt \
		--nt-fw-key-cert $(BINS)/nt_fw_key.crt \
		--nt-fw-cert $(BINS)/nt_fw_cert.crt \
		--nt-fw $(BINS)/SKY1_BL33_UEFI.fd \
		$(BINS)/bootloader3.img

clean:
	rm -rf $(BUILD_OUTPUT)
