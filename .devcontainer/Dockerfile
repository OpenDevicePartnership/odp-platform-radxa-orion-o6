# Dockerfile for Radxa Orion O6 firmware build environment
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# Install build dependencies
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
    && rm -rf /var/lib/apt/lists/*

# Download and install ARM GNU toolchain
RUN mkdir -p /tools && \
    cd /tools && \
    wget --progress=bar:force https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz && \
    tar xvf arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz && \
    rm arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz

# Set up environment variables
ENV GCC5_AARCH64_PREFIX=/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin/aarch64-none-elf-
ENV PATH="/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf/bin:${PATH}"

# Verify toolchain installation
RUN aarch64-none-elf-gcc --version && \
    echo "Toolchain installed successfully at: $(which aarch64-none-elf-gcc)"

# Allow git to work with mounted volumes owned by different users
RUN git config --global --add safe.directory '*'
