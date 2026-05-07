# @file Makefile
#
# Radxa Secure Services Build file
#
# SPDX-License-Identifier: MIT

# Guard: this makefile must be invoked from the root makefile
ifndef ODP_PATH_BUILD_OUTPUT
$(error This makefile must be invoked from the root makefile)
endif

EC_RUST_BIN := $(ODP_PATH_BUILD_OUTPUT)/orion-o6-ec-sp.bin
EC_RUST_DTS := $(ODP_PATH_BUILD_OUTPUT)/orion-o6-ec-sp.dts
EC_SECURE_DTS := platform/linker/orion-o6-ec-sp.dts

# Optional cargo features (e.g. test-bypass-locality-check for e2e tests)
CARGO_FEATURES ?=

# Cargo profile to build with (release or coverage)
CARGO_PROFILE ?= release

all: $(EC_RUST_BIN) $(EC_RUST_DTS)

# ------------------------------------------------------------
# Check and install cargo-binutils if needed
# ------------------------------------------------------------
.PHONY: check-cargo-binutils
check-cargo-binutils:
	@command -v cargo-objcopy >/dev/null 2>&1 || \
	(echo "Installing cargo-binutils..." && cargo install cargo-binutils)
	@rustup target list | grep -q "aarch64-unknown-none (installed)" || \
	(echo "Installing aarch64-unknown-none target..." && rustup target add aarch64-unknown-none)
	@rustup component list | grep -q "llvm-tools.*installed" || \
	(echo "Installing llvm-tools component..." && rustup component add llvm-tools)

# ------------------------------------------------------------
# Build Secure EC Service
# ------------------------------------------------------------
$(EC_RUST_BIN): $(EC_RUST_DTS) check-cargo-binutils
	cd platform && \
	cargo objcopy --target=aarch64-unknown-none --profile $(CARGO_PROFILE) $(if $(CARGO_FEATURES),--features=$(CARGO_FEATURES),) -- -O binary $(EC_RUST_BIN) \

# ------------------------------------------------------------
# Copy DTS file to build directory
# ------------------------------------------------------------
$(EC_RUST_DTS): $(EC_SECURE_DTS)
	mkdir -p $(ODP_PATH_BUILD_OUTPUT)
	cp $(EC_SECURE_DTS) $(EC_RUST_DTS)

clean:
	rm $(EC_RUST_BIN)
	rm $(EC_RUST_DTS)
	cd platform && cargo clean

.PHONY: all clean
