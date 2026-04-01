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

# Standardizing on a specific Rustup version
ARG RUSTUP_VERSION=1.28.2
ARG RUSTUP_URL="https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init"
ARG RUSTUP_INIT_SHA256=20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c

# Non-root user configuration, fallback to vscode if not provided.
ARG USERNAME=vscode

# Container environment variables
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH="/usr/local/cargo/bin:${PATH}"

# Commands to update the apt store, install build dependencies, and clean up apt caches to reduce image size
# [Local Build] If setting up a local build environment, these apps are needed, but the final 'rm' command is only to
#               reduce image size and is not necessary for local development outside a container
RUN apt-get update && apt-get install -y \
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
    sudo && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user (replace pre-existing ubuntu user in Ubuntu 24.04 which occupies UID/GID 1000).
RUN (userdel -f ubuntu || echo "Warning: ubuntu user does not exist, skipping userdel") \
    && groupadd --gid 1000 $USERNAME \
    && useradd --uid 1000 --gid 1000 -m -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install the Python dependencies
# [Local Build] If setting up a local build environment, the pip packages are needed
RUN pip3 install --break-system-packages cryptography

# Download, install, and verify integrity of the Rust toolchain
# [Local Build] If setting up a local build environment, Rust is needed but the text in this section is very specific
#               to a container environment. For local development outside a container, it is recommended to install
#               Rust using the official rustup installer from https://rustup.rs/
RUN curl --proto '=https' --tlsv1.2 -sSf "${RUSTUP_URL}" -o /tmp/rustup-init \
    && echo "${RUSTUP_INIT_SHA256} */tmp/rustup-init" | sha256sum -c - \
    && chmod +x /tmp/rustup-init \
    && /tmp/rustup-init -y --profile minimal --no-modify-path \
    && rm /tmp/rustup-init \
    && chown -R 1000:1000 ${RUSTUP_HOME} ${CARGO_HOME}

# Allow git to work with mounted volumes owned by different users
RUN git config --system --add safe.directory /workspace

# Switch to non-root user
USER $USERNAME

# Default command for 'run'
CMD ["sleep", "infinity"]
