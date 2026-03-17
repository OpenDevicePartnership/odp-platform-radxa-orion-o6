# Build Details

The recommended method for building is using a container and following the steps outlined in the root README.md file, but the following outlines other options for the build process.

## Make Targets

Makefiles are used to build the final output of this repository.  Running `make` or `make all` in the root will invoke each binary and image folder's makefile, create a sub-folder in the `Build` directory named after the corresponding binary or image, and place all build remnants along with the final output in that sub-folder.

Specific components can be built iteratively as build targets on the root makefile (example: make uefi).  And the build infrastructure supports two targets, `TARGET=DEBUG` (default) and `TARGET=RELEASE`.

## Visual Studio Remote Session in the Dev Container

Visual Studio Code has a mechanism where it can host [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers).  This is a little more complicated for setup, but provides a single environment to work with Git, modify code, compile, etc., all within a single editor and honoring things like proper line endings if using WSL.

The link above provides full instructions for setting up this scenario using the docker and json files in the `.devcontainer/` directory.  But if you are already familiar with VSCode and have it installed, you can quickly enter the remote development environment by performing the following steps:

[Windows]

1. Launch VSCode and click the `Open a Remote Window` button in the bottom left corner.

2. Select `Connect to WSL`, navigate to and open the directory containing this repo

3. Click the `Open a Remote Window` button a second time.

4. Select `Reopen in Container`.

[Linux]

1. Launch VSCode and open this repository's folder as the project

2. Click the `Open a Remote Window` button in the bottom left corner.

3. Select `Reopen in Container`.

VSCode will use the devcontainer.json and Dockerfile files to launch a remote development environment within the container that allows running `make` in a terminal, performing git commands, editing files, etc.

## Building Manually

If you wish to build the FW in a native Linux environment or in WSL without a container, the following steps can be followed.

They assume you are running Ubuntu 24.04 and the current working directory is the root of this repository.  Other distributions may require different package names.

1. Install the required system packages

   ``` bash
   sudo apt-get update
   sudo apt-get install -y \
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
      python-is-python3
   ```

2. Install the Python `cryptography` package

   ``` bash
   pip3 install cryptography
   ```

3. Download and extract the AArch64 bare-metal GNU toolchain version 13.2

   If using WSL, do not extract the files in a Windows environment then copy to the `//wsl.localhost` path since that results in losing specific file attributes Linux relies upon.

   ``` bash
   cd tools
   wget https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz
   tar xf arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz
   rm arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz
   ```

4. Install the Rust toolchain

   ``` bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
   source "$HOME/.cargo/env"
   ```

From here you can run any of the make targets, work with Git, etc.
