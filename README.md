# ODP Platform — Radxa Orion O6

This repository is designed to be a demonstration of the Open Device Partnership firmware and software solutions.  It is based on a modified community version of the [CIX P1 BIOS](https://github.com/cixtech/bios) that boots the Radxa Orion O6 hardware and includes features and optimizations from the ODP organization.

## Folder Structure and Content

The repository contains all resources necessary to produce a firmware binary image and an os image that can be used to boot the platform.  The top-level directories are as follows:

- Dot-prefixed (`.devcontainer/`, `.github/`, etc.)

   These directories contain infrastructure and tooling for the development environment, CI/CD pipelines, etc.  No code that is part of the final images will reside in these folders.

- `common/`

   This folder contains tools, documentation, and code files shared by 1 or more of the folders that produce artifacts.  They may be directly linked by the build process of either a binary or image artifact.

- `docs`

   This folder contains detailed documentation specific to this repository.  It is intended to supplement the `common/docs/` directory.

- `bin-???`

   The directories prefixed with `bin-` contain code to produce a single binary artifact that will be used when creating the final firmware binary image.  None of these directories will need access to code in another bin directory, but may require access to code in the common directory or may require the artifact produced by another bin directory.

- `image-???`

   The directories prefixed with `image-` contain scripts and resources to stitch artifacts from the bin directories and open source repositories into final images that can be used to boot the system.

## Quick Start - Building

Since this is a demonstration repository, there is a single build target for configuration but there is support for minor targets such as debug and release.  The simplest way to pull the code and compile is to follow the flow used by the CI/CD GitHub action in a Linux container.  For other options, please refer to the [Build Details](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/blob/main/docs/build_details.md) document for more information.

1) If building in Windows, you will need to install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) and open a command window to provide a Linux environment.  If building in Linux, skip to step 2.

   Note:  The WSL file system can be accessed from Windows by using the path `\\wsl.localhost\...` and the Windows drives can be accessed from WSL by using the path `/mnt/<drive letter>/...`.  But every access across that boundary has delays which adds significant compilation time to the build.  It is highly recommended to clone and build all within WSL then use those paths when copying build remnants.

2) Clone this repository and switch to the root of the directory.

   ``` bash
   git clone https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6.git
   cd odp-platform-radxa-orion-o6
   ```

3) Install a container manager to build and run the development container.  [Docker](https://www.docker.com/get-started/) is typically used in corporate environments, but [Podman](https://podman.io/) is an open source manager that is a little simpler to get started with.  Both use the same command line interfaces, so this demonstration will proceed with Podman.

4) Build the container image using the following command.  The command line parameters were generated using the information in the `.devcontainer/` directory.  Note the use of the `.` at the end of the command.

   ``` bash
   podman build \
      --tag odp-orion-o6 \
      --file .devcontainer/Dockerfile \
      --build-arg USERNAME=$(whoami) \
      .
   ```

5) Start the container in detached mode so that it is waiting for an execute command and its workspace is mapped to the current directory.

   ``` bash
   podman run \
      --detach \
      --name odp-build \
      --userns=keep-id \
      --workdir /workspace \
      --volume "$PWD:/workspace" \
      odp-orion-o6 \
      sleep infinity
   ```

   The above command assigns the name `odp-build` so that the next time you want to start the container (for instance after a reboot), you only need to execute the following:

   ``` bash
   podman start odp-build 
   ```

6) Use the container exec command to execute `make` within the container. The parameter `TARGET=DEBUG` is not necessary since it is the default, but is here to demonstrate command parameters for make.

   ``` bash
   podman exec -it odp-build make TARGET=DEBUG
   ```

   The directory `Build/` will be created and will contain a directory for each binary, a `cix-flash-all.bin` file to be written to the SPINOR and an `os_installer` directory with the image to update a USB key to install the OS to the NVME drive.

7) A reboot will automatically shutdown the container, but to force it to free resources, run:

   ``` bash
   podman stop odp-build
   ```

   And to remove the container entirely, run:

   ``` bash
   podman rm odp-build
   ```

## Quick Start - Booting

**TBD**:  Need to document flashing pre-compiled binaries and reference binaries from the build process
