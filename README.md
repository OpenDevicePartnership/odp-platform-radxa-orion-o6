# ODP Platform — Radxa Orion O6

This repository is designed to be a demonstraion of ODP FW and SW solutions.  It is based on a modified community version of the [CIX P1 BIOS](https://github.com/cixtech/bios) that boots the Radxa Orion O6 hardware and includes features and optimizations from the ODP organization.

Since this is a demonstration repository, there is a single build target for configuration but there is support for minor targets such as debug and release.  Details are outlined in the `docs/` directory.

## Folder Structure and Content

The repository contains all resources necessary to produce a firmware binary image and an os image that can be used to boot the platform.  The top-level directories are as follows:

- Dot-prefixed (`.devcontainer/`, `.github/`, etc.)

   These directories contain infrastructure and tooling for the development environment, CI/CD pipelines, etc.  No code that is part of the final images will reside in these folders.

- `common/`

   This folder contains tools, documentation, and code files shared by 1 or more of the folders that produce artifacts.  They may be directly linked by the build process of either a binary or image artifact.

- `docs`

   This folder contains detailed documentation specific to this repository.  It is intended to suppliment the `common/docs/` directory.

- `bin-???`

   The directories prefixed with `bin-` contain code to produce a single binary artifact that will be used when creating the final firmware binary image.  None of these directories will need access to code in another bin directory, but may require access to code in the common director or may require the artifact produced by another bin directory.

- `image-???`

   The directories prefixed with `image-` contain scripts and resources to stitch artifacts from the bin directories and open source repositories into final images that can be used to boot the system.

## Quick Start - Building

The simplest way to pull the code and boot the reference system is to follow the flow used by the CI/CD GitHub action and use a Linux container.  Please refer to the [Build Details](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/blob/main/docs/build_details.md) document for more information.

1) If building in Windows, you will need to install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) to provide a Linux environment, then open a WSL command prompt to continue with step 2.

   Note:  The WSL file system can be accessed from Windows by using the path `\\wsl.localhost\...` and the Windows drives can be accessed from WSL by using the path `/mnt/<drive letter>/...`.  But every access across that boundary has delays which adds significant compilation time to the build.  It is highly recommended to clone and build all within WSL then use those paths when copying build remnants.

2) Clone this repository and switch to the root of the directory.

   ``` bash
   git clone https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6.git
   cd odp-platform-radxa-orion-o6
   ```

3) Install [Podman](https://podman.io/) to manage installing and running a build environment container.  Docker, which is typically used in corporate environments and supports the same command line prompts can also be installed.

4) Build a container using the information in the `.devcontainer/` directory.  Note the use of the `.` at the end of the command.

   ``` bash
   podman build \
      --tag odp-orion-o6 \
      --file .devcontainer/Dockerfile \
      --build-arg USERNAME=$(whoami) \
      .
   ```

5) Make is used to compile the code, so the following command is used to launch the container mapped to this directory, execute make within the container, then exit.  The parameter `TARGET=DEBUG` is not necessary since it is the default, it is here to demonstrate command parameters for make.

   ``` bash
   podman run \
      --rm \
      --interactive \
      --tty \
      --userns=keep-id \
      --workdir /workspace \
      --volume "$PWD:/workspace" \
      odp-orion-o6 \
      make TARGET=DEBUG
   ```

6) The directory `Build/` will be created and will contain a directory of all remnants when compiling each bin directory, a `cix-flash-all.bin` file to be written to the SPINOR and an `os_installer` directory with the image to update a USB key to install the OS to the NVME drive.

## Quick Start - Booting

**TBD**:  Need to document flashing pre-compiled binaries and reference binaries from the build process
