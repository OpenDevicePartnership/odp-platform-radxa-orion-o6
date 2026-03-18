# Dockerfile for Radxa Orion O6 firmware build environment
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# SHA256 checksums for downloaded artifacts (override via build args)
# https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz.sha256asc
ARG GCC_TOOLCHAIN_SHA256=7fe7b8548258f079d6ce9be9144d2a10bd2bf93b551dafbf20fe7f2e44e014b8
# https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init.sha256
ARG RUSTUP_VERSION=1.28.2
ARG RUSTUP_INIT_SHA256=20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c

# Non-root user configuration, fallback to vscode if not provided.
ARG USERNAME=vscode

# Set up environment variables
ENV GCC5_AARCH64_PREFIX=/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH="/usr/local/cargo/bin:/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin:${PATH}"

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
    && rm -rf /var/lib/apt/lists/* \
    # Create non-root user (replace pre-existing ubuntu user in Ubuntu 24.04 which occupies UID/GID 1000).
    && (userdel -f ubuntu || echo "Warning: ubuntu user does not exist, skipping userdel") \
    && groupadd --gid 1000 $USERNAME \
    && useradd --uid 1000 --gid 1000 -m -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # Download and install ARM GNU toolchain
    && mkdir -p /tools \
    && cd /tools \
    && wget --progress=bar:force https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz \
    && echo "${GCC_TOOLCHAIN_SHA256}  arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz" | sha256sum -c - \
    && tar xf arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz \
    && rm arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz \
    # Verify toolchain installation
    && aarch64-none-elf-gcc --version \
    && echo "Toolchain installed successfully at: $(which aarch64-none-elf-gcc)" \
    # Install Python dependencies (cryptography is needed by edk2 build)
    && pip3 install --break-system-packages cryptography \
    # Install Rust toolchain (cargo is needed by the build). Newer version is required than the one available
    # in Ubuntu 24.04 repos for edk2 build to work.
    # Uses a pinned rustup version for reproducible builds. To update, change RUSTUP_VERSION and RUSTUP_INIT_SHA256.
    # Installed system-wide so it is accessible by any user.
    && curl --proto '=https' --tlsv1.2 -sSf \
        "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init" \
        -o /tmp/rustup-init \
    && echo "${RUSTUP_INIT_SHA256} */tmp/rustup-init" | sha256sum -c - \
    && chmod +x /tmp/rustup-init \
    && /tmp/rustup-init -y --no-modify-path \
    && rm /tmp/rustup-init \
    && chown -R 1000:1000 ${RUSTUP_HOME} ${CARGO_HOME} \
    # Allow git to work with mounted volumes owned by different users
    && git config --system --add safe.directory /workspace

# Switch to non-root user
USER $USERNAME

# Default command for manual docker run (VS Code overrides this with its own keep-alive)
CMD ["sleep", "infinity"]
