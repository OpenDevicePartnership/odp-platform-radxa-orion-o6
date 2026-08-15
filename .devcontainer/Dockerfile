# ODP Dockerfile for Radxa Orion O6 firmware build environment
#
# SPDX-License-Identifier: MIT
#

# A separate amd64 image stage that provides just the glibc shared libraries the closed-source x86_64 CIX tools
# need (cix_package_tool, cix_regen_trusted_key_cert, cert_uefi_create_rsa - see bootchain/Makefile), so QEMU
# user-mode emulation (qemu-x86_64, installed below) can run them directly on a non-x86_64 host.  Only files are
# copied out of this stage below (nothing is ever executed in it), so pulling it requires no QEMU/emulation support
# at image build time - only 'qemu-x86_64' itself is needed later, at container runtime.
FROM --platform=linux/amd64 ubuntu:24.04 AS amd64-libs

FROM ubuntu:24.04

# Set non-interactive to avoid prompts during build
ARG DEBIAN_FRONTEND=noninteractive

# Standardizing on a specific Rustup version. When bumping RUSTUP_VERSION, update the checksums below to match from
# https://static.rust-lang.org/rustup/archive/<version>/<target>/rustup-init.sha256).
ARG RUSTUP_VERSION=1.28.2
ARG RUSTUP_URL_BASE="https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}"
ARG RUSTUP_SHA256_X86_64=20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c
ARG RUSTUP_SHA256_AARCH64=e3853c5a252fca15252d07cb23a1bdd9377a8c6f3efa01531109281ae47f841c

# Non-root user configuration, fallback to vscode if not provided.
ARG USERNAME=vscode

# Container environment variables
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH="/usr/local/cargo/bin:${PATH}" \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1

# Commands to update the apt store, install build dependencies, and clean up apt caches to reduce image size
# [Local Build] If setting up a local build environment, these apps are needed, but the final 'rm' command is only to
#               reduce image size and is not necessary for local development outside a container
#
# qemu-user is installed regardless of the container's own architecture so that, on a non-x86_64 host, QEMU
# user-mode emulation (qemu-x86_64) can run the closed-source x86_64-only CIX tools directly; this is a no-op on an
# x86_64 host, since amd64 is already its native architecture.
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
    qemu-user \
    sudo && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Shared libraries needed by the closed-source x86_64 CIX tools (checked via 'readelf -d ...'), copied to their
# standard multiarch paths so 'qemu-x86_64' can resolve them without a custom sysroot argument.
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
# [Local Build] If setting up a local build environment, Rust is needed but the text in this section is very specific
#               to a container environment. For local development outside a container, it is recommended to install
#               Rust using the official rustup installer from https://rustup.rs/
RUN case "$(uname -m)" in \
        x86_64)  RUSTUP_TARGET="x86_64-unknown-linux-gnu";  RUSTUP_SHA256="${RUSTUP_SHA256_X86_64}" ;; \
        aarch64) RUSTUP_TARGET="aarch64-unknown-linux-gnu"; RUSTUP_SHA256="${RUSTUP_SHA256_AARCH64}" ;; \
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
