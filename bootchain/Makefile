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

# cix_package-tool is a vendor submodule that only ships closed-source x86_64 builds of cix_package_tool,
# cix_regen_trusted_key_cert, and cert_uefi_create_rsa (no source is available to build them natively).  On a
# non-x86_64 host (e.g. Arm64), including inside the project's now architecture-native container, they are run
# through QEMU user-mode emulation directly (ODP_RUN_AMD64) instead of requiring an emulated container for the whole
# build; on an x86_64 host they already run natively and ODP_RUN_AMD64/ODP_CHECK_AMD64_EMULATION are empty.  The
# glibc libraries QEMU needs come from one of two places: on the bare host, a small local sysroot is built with
# podman (no system changes required); inside the project's own container, podman is not available, so the same
# libraries are instead baked into standard system paths at image build time (see .devcontainer/Dockerfile).
# fiptool and cert_create, by contrast, are standard open-source TF-A host tools already vendored under
# modules/tf-a, so they are always built natively for the host architecture instead of using the prebuilt x86_64
# copies in cix_package-tool.
export ODP_PATH_TFA_SRC             := $(CURDIR)/modules/tf-a/arm-trusted-firmware-cix-odp
export ODP_PATH_HOST_TOOLS          := $(ODP_PATH_BUILD_OUTPUT)/mod/host-tools
export ODP_PATH_AMD64_SYSROOT       := $(ODP_PATH_BUILD_OUTPUT)/mod/amd64-sysroot
FIPTOOL                             := $(ODP_PATH_HOST_TOOLS)/fiptool
CERT_CREATE_RSA                     := $(ODP_PATH_HOST_TOOLS)/cert_create_rsa

# Shared libraries needed by the closed-source x86_64 tools (checked via 'readelf -d ...').
AMD64_SYSROOT_LIBS := \
	lib64/ld-linux-x86-64.so.2 \
	lib/x86_64-linux-gnu/libc.so.6 \
	lib/x86_64-linux-gnu/libm.so.6 \
	lib/x86_64-linux-gnu/libdl.so.2 \
	lib/x86_64-linux-gnu/libpthread.so.0

ifeq ($(shell uname -m),x86_64)
ODP_RUN_AMD64               :=
ODP_CHECK_AMD64_EMULATION   :=
else ifeq ($(shell command -v podman 2>/dev/null),)
# No podman (e.g. inside the project's own container): the amd64 libraries are already baked into standard system
# paths at image build time, so just verify qemu-x86_64 is present.
ODP_RUN_AMD64               := qemu-x86_64
ODP_CHECK_AMD64_EMULATION   := check-amd64-emulation
else
# podman is available (e.g. the bare host): build a small local sysroot instead of touching system paths.
ODP_RUN_AMD64               := qemu-x86_64 -L $(ODP_PATH_AMD64_SYSROOT)
ODP_CHECK_AMD64_EMULATION   := $(ODP_PATH_AMD64_SYSROOT)/.stamp
endif

# Build targets are all PHONY and rely on the module's makefiles to determine if a build is necessary
.PHONY: all clean distclean test stitch-all pre-built bootloader2 bootloader3 check-amd64-emulation

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
	$(MAKE) -C $(ODP_PATH_TFA_SRC)/tools/fiptool realclean
	$(MAKE) -C $(ODP_PATH_TFA_SRC)/tools/cert_create realclean
	rm -rf $(ODP_PATH_DOWNLOADS)

# A call into each module's test target
test:
	$(MAKE) -C modules/uefi test
	cd $(ODP_PATH_COMMON)/tests/acpi && cargo test

# Bootchain stitch and packaging targets
stitch-all: bootloader2 bootloader3 $(ODP_CHECK_AMD64_EMULATION)
	cd $(ODP_PATH_BINS_OUTPUT) && \
	$(ODP_RUN_AMD64) $(ODP_PATH_PACKAGE_TOOL)/cix_package_tool \
		-c $(ODP_PATH_COMMON)/spi_flash_config_all.json \
		-o $(ODP_PATH_BUILD_OUTPUT)/odp_orion_o6_bootchain.bin

pre-built:
	mkdir -p $(ODP_PATH_BINS_OUTPUT)
	cp -f $(ODP_PATH_PACKAGE_TOOL)/Firmwares/* $(ODP_PATH_BINS_OUTPUT)/
	cp -f $(ODP_PATH_COMMON)/cix-edk2-platforms/Platform/Radxa/Orion/O6/Firmwares/* $(ODP_PATH_BINS_OUTPUT)/
	head -c 8192 /dev/zero | tr '\000' '\377' > $(ODP_PATH_BINS_OUTPUT)/dummy.bin

# fiptool and cert_create are standard open-source TF-A host tools; build them natively for the host architecture
# instead of relying on the prebuilt x86_64 copies in cix_package-tool.  COT=dualroot matches CIX's cert layout: the
# Trusted Key Certificate here only requires --rot-key/--trusted-world-key (no --non-trusted-world-key), since the
# non-trusted world root is regenerated independently in bootloader3 (cix_regen_trusted_key_cert -> trusted_key_no.crt).
$(FIPTOOL):
	$(MAKE) -C $(ODP_PATH_TFA_SRC)/tools/fiptool
	mkdir -p $(ODP_PATH_HOST_TOOLS)
	cp -f $(ODP_PATH_TFA_SRC)/tools/fiptool/fiptool $@

$(CERT_CREATE_RSA):
	$(MAKE) -C $(ODP_PATH_TFA_SRC)/tools/cert_create COT=dualroot
	mkdir -p $(ODP_PATH_HOST_TOOLS)
	cp -f $(ODP_PATH_TFA_SRC)/tools/cert_create/cert_create $@

# QEMU user-mode emulation runs the closed-source x86_64 CIX tools directly, without emulating an entire container.
# This check only applies when podman is unavailable (see ODP_RUN_AMD64 above); otherwise the sysroot rule below
# builds what's needed automatically.  Requires 'qemu-x86_64' (Debian/Ubuntu: 'sudo apt-get install qemu-user') plus
# the glibc libraries baked into the project's container image (.devcontainer/Dockerfile).
check-amd64-emulation:
	@command -v qemu-x86_64 >/dev/null 2>&1 || { \
		echo "ERROR: qemu-x86_64 not found.  Install it with: sudo apt-get install qemu-user" >&2; \
		exit 1; \
	}
	@ls /lib/x86_64-linux-gnu/libc.so.6 >/dev/null 2>&1 || { \
		echo "ERROR: amd64 glibc libraries not found at /lib/x86_64-linux-gnu/.  This host has no podman to build a" >&2; \
		echo "       local sysroot automatically (see ODP_PATH_AMD64_SYSROOT rule); install podman, or install these" >&2; \
		echo "       libraries manually." >&2; \
		exit 1; \
	}

# A minimal glibc sysroot lets QEMU user-mode emulation run the closed-source x86_64 CIX tools directly, without
# emulating an entire container or modifying system paths.  Pulled once from a throwaway amd64 container image.
$(ODP_PATH_AMD64_SYSROOT)/.stamp:
	mkdir -p $(ODP_PATH_AMD64_SYSROOT)
	cid=$$(podman create --platform linux/amd64 docker.io/library/ubuntu:24.04 true); \
	for lib in $(AMD64_SYSROOT_LIBS); do \
		mkdir -p $(ODP_PATH_AMD64_SYSROOT)/$$(dirname $$lib); \
		podman cp "$$cid:/$$lib" $(ODP_PATH_AMD64_SYSROOT)/$$lib; \
	done; \
	podman rm -f "$$cid" >/dev/null
	touch $@

bootloader2: $(FIPTOOL) $(CERT_CREATE_RSA)
	$(CERT_CREATE_RSA) \
		--key-alg rsa \
		--key-size 3072 \
		--hash-alg sha256 \
		--tfw-nvctr 31 \
		--rot-key $(ODP_PATH_OEM_PRIVATE_KEY) \
		--trusted-world-key $(ODP_PATH_OEM_PRIVATE_KEY) \
		--soc-fw-key $(ODP_PATH_OEM_PRIVATE_KEY) \
		--tos-fw-key $(ODP_PATH_OEM_PRIVATE_KEY) \
		--scp-fw-key $(ODP_PATH_OEM_PRIVATE_KEY) \
		--prot-key $(ODP_PATH_OEM_PRIVATE_KEY) \
		--trusted-key-cert $(ODP_PATH_BINS_OUTPUT)/trusted_key.crt \
		--soc-fw-key-cert $(ODP_PATH_BINS_OUTPUT)/bl31_fw_key.crt \
		--tos-fw-key-cert $(ODP_PATH_BINS_OUTPUT)/tos_fw_key.crt \
		--soc-fw-cert $(ODP_PATH_BINS_OUTPUT)/bl31_fw_content.crt \
		--tos-fw-cert $(ODP_PATH_BINS_OUTPUT)/tos_fw_cert.crt \
		--soc-fw $(ODP_PATH_BINS_OUTPUT)/bl31.bin \
		--tos-fw $(ODP_PATH_BINS_OUTPUT)/tee-raw.bin
	$(FIPTOOL) create \
		--soc-fw $(ODP_PATH_BINS_OUTPUT)/bl31.bin \
		--tos-fw $(ODP_PATH_BINS_OUTPUT)/tee-raw.bin \
		--trusted-key-cert $(ODP_PATH_BINS_OUTPUT)/trusted_key.crt \
		--soc-fw-key-cert $(ODP_PATH_BINS_OUTPUT)/bl31_fw_key.crt \
		--tos-fw-key-cert $(ODP_PATH_BINS_OUTPUT)/tos_fw_key.crt \
		--soc-fw-cert $(ODP_PATH_BINS_OUTPUT)/bl31_fw_content.crt \
		--tos-fw-cert $(ODP_PATH_BINS_OUTPUT)/tos_fw_cert.crt \
		$(ODP_PATH_BINS_OUTPUT)/bootloader2.img

bootloader3: $(FIPTOOL) $(ODP_CHECK_AMD64_EMULATION)
	$(ODP_RUN_AMD64) $(ODP_PATH_PACKAGE_TOOL)/cix_regen_trusted_key_cert \
		-p $(ODP_PATH_PACKAGE_TOOL)/Keys/oem_publickey.pem \
		-s $(ODP_PATH_OEM_PRIVATE_KEY) \
		-o $(ODP_PATH_BINS_OUTPUT)/trusted_key_no.crt
	$(ODP_RUN_AMD64) $(ODP_PATH_PACKAGE_TOOL)/cert_uefi_create_rsa \
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
	$(FIPTOOL) create \
		--trusted-key-cert $(ODP_PATH_BINS_OUTPUT)/trusted_key_no.crt \
		--nt-fw-key-cert $(ODP_PATH_BINS_OUTPUT)/nt_fw_key.crt \
		--nt-fw-cert $(ODP_PATH_BINS_OUTPUT)/nt_fw_cert.crt \
		--nt-fw $(ODP_PATH_BINS_OUTPUT)/SKY1_BL33_UEFI.fd \
		$(ODP_PATH_BINS_OUTPUT)/bootloader3.img
