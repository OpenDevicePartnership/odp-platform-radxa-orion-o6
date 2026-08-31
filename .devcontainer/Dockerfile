# ODP Dockerfile for Radxa Orion O6 firmware build environment
#
# SPDX-License-Identifier: MIT
#

# The container hosts Ubuntu with the amd64-libs providing support to run the pre-compiled x86_64 CIX tools on a
# non-x86_64 host.  This is a no-op if running on an x86_64 host, but is required for aarch64 hosts.
FROM --platform=linux/amd64 ubuntu:24.04 AS amd64-libs
FROM ubuntu:24.04

# The 'enter-container.sh' script searches this file for 'ARG ODP_IMAGE_VERSION=' and compares the value against
# any existing container 'odp.image-version' label. Increment this value any time changes are made that require
# existing images to be rebuilt.
ARG ODP_IMAGE_VERSION=4
LABEL odp.image-version="${ODP_IMAGE_VERSION}"

# Set non-interactive to avoid prompts during build
ARG DEBIAN_FRONTEND=noninteractive

# Standardizing on a specific Rustup version. 
ARG RUSTUP_VERSION=1.28.2
ARG RUSTUP_URL_BASE="https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}"
ARG RUSTUP_TARGET_X86_64="x86_64-unknown-linux-gnu"
ARG RUSTUP_SHA256_X86_64=20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c
ARG RUSTUP_TARGET_AARCH64="aarch64-unknown-linux-gnu"
ARG RUSTUP_SHA256_AARCH64=e3853c5a252fca15252d07cb23a1bdd9377a8c6f3efa01531109281ae47f841c

# Non-root user configuration, fallback to vscode if not provided.
ARG USERNAME=vscode

# Container environment variables
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH="/usr/local/cargo/bin:${PATH}" \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1

# Install all build dependencies within a single 'RUN' stage to help reduce the image size.
# [Local Build] If setting up a local build environment, these apps are needed, but the final 'rm' command is only to
#               reduce image size and is not necessary for local development outside a container
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    python3 \
    python3-pip \
    python3-setuptools \
    uuid-dev \
    acpica-tools \
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
    dotnet-sdk-8.0 \
    ca-certificates \
    gnupg \
    qemu-user-static \
    sudo && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Shared libraries needed by the pre-compiled x86_64 CIX tools on an ARM host.
# [Local Build] If setting up a local build environment on an ARM host, the qemu-user binaries are needed
COPY --from=amd64-libs /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=amd64-libs /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=amd64-libs /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
COPY --from=amd64-libs /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2
COPY --from=amd64-libs /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/libpthread.so.0

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
# [Local Build] If setting up a local build environment, Rust is needed but the text in this 'RUN' stage is very
#               specific to a container environment. For local development outside a container, it is best to follow
#               the instructions at https://www.rust-lang.org/tools/install
RUN case "$(uname -m)" in \
        x86_64)  RUSTUP_TARGET="${RUSTUP_TARGET_X86_64}";  RUSTUP_SHA256="${RUSTUP_SHA256_X86_64}" ;; \
        aarch64) RUSTUP_TARGET="${RUSTUP_TARGET_AARCH64}"; RUSTUP_SHA256="${RUSTUP_SHA256_AARCH64}" ;; \
        *) echo "ERROR: No pinned rustup-init for architecture '$(uname -m)'." >&2; exit 1 ;; \
    esac \
    && curl --proto '=https' --tlsv1.2 -sSf \
        "${RUSTUP_URL_BASE}/${RUSTUP_TARGET}/rustup-init" -o /tmp/rustup-init \
    && echo "${RUSTUP_SHA256} */tmp/rustup-init" | sha256sum -c - \
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
