# ODP Platform — Radxa Orion O6

[![Build](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/actions/workflows/build.yml/badge.svg)](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/actions/workflows/build.yml)
[![Test](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/actions/workflows/test.yml/badge.svg)](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

This repository contains the bare minimum firmware and OS image resources needed to boot a Radxa Orion O6 platform, serving as a demonstration of ODP features.  It is based on the [Orion O6 Documentation](https://radxa.com/products/orion/o6/#documentation) and the [CIX P1 BIOS](https://github.com/cixtech/bios) with specifics to the ODP changes documented in the README.md files in the root of each top-level directory.

## Folder Structure and Content

The top-level directories are organized as follows:

| Directory | Purpose |
| --- | --- |
| `.devcontainer/`, `.github/`, etc. | Infrastructure and tooling for the development environment, CI/CD pipelines, etc.  No code that is part of the final images will reside in these folders. |
| `common/` | Tools, documentation, and code files shared by one or more of the folders that produce artifacts. |
| `bin-*/` | Each directory makefile will produce a single binary artifact for the firmware image.  None will link code from another bin directory, but may link code from the common directory or require an artifact from another bin directory. |
| `image-*/` | Scripts and resources to stitch artifacts into final images that can be used to boot the system. |

## Quick Start - Building

This repository has a single configuration for simplicity, but does support DEBUG and RELEASE targets.  The fastest way to compile is to follow the flow used by the CI/CD GitHub action in a Linux container.  For other options, please refer to the [image-bootchain/README.md](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/blob/HEAD/image-bootchain/README.md) file.

1) If building in Windows, install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) and open a command window to provide a Linux environment.  If building in Linux, skip to step 2.

   Note:  The WSL file system can be accessed from Windows by using the path `\\wsl.localhost\...` and the Windows drives can be accessed from WSL by using the path `/mnt/<drive letter>/...`.  But every access across that boundary has delays that can add significant time to the build.  It is highly recommended to clone and build within WSL then use those paths when copying build remnants.

2) Clone this repository making sure to pull all submodule code and switch to the root of the directory.

   ``` bash
   git clone --recurse-submodules https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6.git
   cd odp-platform-radxa-orion-o6
   ```

3) Install a container manager to build and run the development container.  [Docker](https://www.docker.com/get-started/) is often used in corporate environments, but [Podman](https://podman.io/) is an open source manager that is a little simpler to get started with and what this demonstration is using.

4) Build, run, and enter the container using this repository as the workspace.  The `./common/tools/enter-container.sh` bash script was written to perform the necessary steps using Podman.  If Docker was installed in step 3, the script CONTAINER_TOOL_NAME variable will need to be updated.

   ``` bash
   ./common/tools/enter-container.sh
   ```

5) Once in the container, execute `make` from the `/workspace` directory to compile and place all remnants in the `build/` directory.

   ``` bash
   make
   ```

Since the container `/workspace` directory was mapped to the repository directory, the `build/` directory can be accessed either inside or outside the container.

## Quick Start - Booting

**TBD**:  Need to document the final outputs from the build process and how to get them onto the platform
