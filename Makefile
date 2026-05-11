# Primary Makefile for the ODP Platform build
#
# SPDX-License-Identifier: MIT
#

SHELL := /bin/bash

# Defines used by this and all child makefiles
export ODP_PATH_BUILD_OUTPUT       ?= $(CURDIR)/build
export ODP_PATH_BINS_OUTPUT        := $(ODP_PATH_BUILD_OUTPUT)/postbuild/bootchain
export ODP_PATH_COMMON             := $(CURDIR)/common
export ODP_PATH_PACKAGE_TOOL       := $(CURDIR)/postbuild/bootchain/cix_package-tool
export ODP_PATH_DOWNLOADS          := $(CURDIR)/downloads
export ODP_PATH_GCC5_PREFIX        := $(ODP_PATH_DOWNLOADS)/gnu-toolchain/bin/aarch64-none-elf-

# NOTE:  This key is being provided for signing demonstration only test binaries and should not be used for
# production signing.  Any production signing should use a secure key management process and private keys
# should not be stored in the repository.
export ODP_PATH_OEM_PRIVATE_KEY    := $(ODP_PATH_PACKAGE_TOOL)/Keys/oem_privatekey.pem

# Build targets are all PHONY and rely on the module's makefiles to determine if a build is necessary
.PHONY: all clean distclean test

# Ordering is specific: Toolchain first, copy the pre-built binaries, build binaries, then final image stitch.
all:
	$(ODP_PATH_COMMON)/tools/download-gnu-toolchain.sh
	$(MAKE) -C postbuild/bootchain pre-built
	$(MAKE) -C mod/uefi all
	$(MAKE) -C mod/tee all
	$(MAKE) -C mod/tf-a all
	$(MAKE) -C mod/mem_config all
	$(MAKE) -C mod/pm_config all
	$(MAKE) -C mod/secure-services all
	$(MAKE) -C postbuild/bootchain stitch-all

# Module's make should not leave any remnant outside the build directory so a normal clean just removes build/
clean:
	rm -rf $(ODP_PATH_BUILD_OUTPUT)

# Distclean is a more thorough clean to target modules that might have things like build tool remnants
distclean: clean
	$(MAKE) -C mod/uefi distclean

# A call into each module's test target
test:
	$(MAKE) -C mod/uefi test
	cd $(ODP_PATH_COMMON)/tests/acpi && cargo test
