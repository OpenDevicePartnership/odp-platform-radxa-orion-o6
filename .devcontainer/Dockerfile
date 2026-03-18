# ODP Dockerfile for Radxa Orion O6 firmware build environment
#
# ## License
#
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: Apache-2.0
FROM ubuntu:24.04

# Set non-interactive to avoid prompts during build
ARG DEBIAN_FRONTEND=noninteractive

# GCC toolchain download SHA256 checksum (override via build args)
# https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz.sha256asc
ARG GCC_TOOLCHAIN_SHA256=7fe7b8548258f079d6ce9be9144d2a10bd2bf93b551dafbf20fe7f2e44e014b8

# Rustup download version and SHA256 checksum (override via build args)
# https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init.sha256
ARG RUSTUP_VERSION=1.28.2
ARG RUSTUP_INIT_SHA256=20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c

# Non-root user configuration, fallback to vscode if not provided.
ARG USERNAME=vscode

# Container environment variables
ENV GCC5_AARCH64_PREFIX=/common/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH="/usr/local/cargo/bin:/common/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin:${PATH}"

# Using a single RUN command to minimize layers and ensure cleanup
RUN \
    # Install build dependencies
    apt-get update && apt-get install -y \
    build-essential \
    git \
    python3 \
    python3-pip \
    python3-setuptools \
    uuid-dev \
    iasl \
    nasm \
    bison \
    flex \
    libssl-dev \
    wget \
    curl \
    xz-utils \
    device-tree-compiler \
    bc \
    python3-pyelftools \
    python-is-python3 \
    sudo \
    #
    # Create non-root user (replace pre-existing ubuntu user in Ubuntu 24.04 which occupies UID/GID 1000).
    && (userdel -f ubuntu || echo "Warning: ubuntu user does not exist, skipping userdel") \
    && groupadd --gid 1000 $USERNAME \
    && useradd --uid 1000 --gid 1000 -m -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    #
    # Download the bare metal ARM GNU toolchain and verify its integrity
    # WARNING, the compressed file uses the name 13.2.rel1 but the extracted folder uses 13.2.Rel1
    && mkdir -p /common/tools \
    && cd /common/tools \
    && wget --progress=bar:force https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz \
    && echo "${GCC_TOOLCHAIN_SHA256}  arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz" | sha256sum -c - \
    && tar xf arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz \
    && rm arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz \
    && aarch64-none-elf-gcc --version \
    && echo "Toolchain installed successfully at: $(which aarch64-none-elf-gcc)" \
    #
    # Install Python dependencies
    && pip3 install --break-system-packages cryptography \
    #
    # Download, install, and verify integrity of the Rust toolchain
    && curl --proto '=https' --tlsv1.2 -sSf \
    "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init" \
    -o /tmp/rustup-init \
    && echo "${RUSTUP_INIT_SHA256} */tmp/rustup-init" | sha256sum -c - \
    && chmod +x /tmp/rustup-init \
    && /tmp/rustup-init -y --no-modify-path \
    && rm /tmp/rustup-init \
    && chown -R 1000:1000 ${RUSTUP_HOME} ${CARGO_HOME} \
    #
    # Allow git to work with mounted volumes owned by different users
    && git config --system --add safe.directory /workspace \
    #
    # Final cleanup to reduce image size
    && rm -rf /var/lib/apt/lists/*

# Switch to non-root user
USER $USERNAME

# Default command for 'run'
CMD ["sleep", "infinity"]
