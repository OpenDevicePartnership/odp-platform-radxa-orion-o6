# ODP Platform — Radxa Orion O6

[![Build](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/actions/workflows/build.yml/badge.svg)](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/actions/workflows/build.yml)
[![Test](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/actions/workflows/test.yml/badge.svg)](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

This repository contains the bare minimum firmware and OS image resources needed to boot a Radxa Orion O6 platform, serving as a demonstration of ODP features.  It is based on the [Orion O6 Documentation](https://radxa.com/products/orion/o6/#documentation) and the [CIX P1 BIOS](https://github.com/cixtech/bios) with ODP-specific changes documented in the README.md file at the root of each top-level directory.

## Folder Structure and Content

The top-level directories each contain a **README.md** file with detailed build instructions, design notes, and component-specific information.  Refer to the [postbuild/bootchain/README.md](postbuild/bootchain/README.md) file for the best end-to-end overview of how all pieces fit together, including available make targets, hardware details, and working with individual components.

| Directory | Purpose |
| --- | --- |
| .devcontainer/ and .github/ | Infrastructure and tooling for the development environment, CI/CD pipelines, etc.  These folders contain no code that is part of the final images. |
| common/ | Tools, documentation, and code files shared by one or more of the folders that produce artifacts. |
| mod/... | Each module directory's Makefile will produce a single binary artifact to be used in one of the postbuild processes.  None of these will link code from another `mod/...` directory, but may link code from `common/` or consume an artifact produced by another module. |
| postbuild/... | Scripts and resources to stitch modules into final images that can be used to boot the system. |

The folder layout is very different than the original CIX P1 BIOS repository, but the boot flow is the same using the sequence **TF-A (BL31) → OP-TEE → UEFI → OS** and it makes heavy use of Git submodules to demonstrate how only minimal changes to external code are needed to support ODP features.  The [.gitmodules](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/blob/HEAD/.gitmodules) file lists all references.  Be sure to clone with `--recurse-submodules` or run `git submodule update --init --recursive` after cloning to fully populate the submodule directories.

In the root of the repository are several pertinent files for contributing:

| File | Purpose |
| --- | --- |
| LICENSE | License information covering this repository. |
| CODE_OF_CONDUCT.md | Community interaction and behavior guidelines. |
| CONTRIBUTING.md | How to submit issues, pull requests, and contribution licensing terms. |
| CODEOWNERS | GitHub CODEOWNERS file defining required reviewers for pull requests. |
| SECURITY.md | Vulnerability disclosure and embargo policy. |

## Quick Start

This repository uses a single build configuration for simplicity but supports both DEBUG and RELEASE targets.  The fastest way to compile is to replicate the CI/CD GitHub Actions workflow inside a Linux container, but for other options, please refer to the [postbuild/bootchain/README.md](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/blob/HEAD/postbuild/bootchain/README.md) file.

1) If building in Windows, install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) and open a command window to provide a Linux environment.  If building in Linux, skip to step 2.

   Note:  The WSL file system can be accessed from Windows by using the path `\\wsl.localhost\...` and the Windows drives can be accessed from WSL by using the path `/mnt/<drive letter>/...`.  However, every access across that boundary introduces delays that can add significant time to the build process.  It is highly recommended to clone and build within WSL then use those paths when copying build remnants.

2) Be sure [Git](https://github.com/git-guides/install-git) is installed then clone this repository making sure to pull all submodule code and switch to the root of the directory.

   ``` bash
   git clone --recurse-submodules https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6.git
   cd odp-platform-radxa-orion-o6
   ```

3) Install a container manager to build and run the development container.  [Docker](https://www.docker.com/get-started/) is often used in corporate environments, but [Podman](https://podman.io/) is an open-source alternative that is simpler to set up and is used throughout this guide.

4) Build and start the development container, mounting this repository as its workspace.  The **enter-container.sh** bash script can be used to perform the necessary steps using Podman.

   ``` bash
   ./common/tools/enter-container.sh
   ```

5) Once in the container, execute `make` from the `/workspace` directory to compile and place all remnants in the `build/` directory.

   ``` bash
   make
   ```

   Because the container's `/workspace` directory is mapped to the host repository directory, the `build/` directory can be accessed either inside or outside the container.

6) **TBD Task #36:**  [Radxa OS Creation and Booting Documentation](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/issues/36)

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow Microsoft's Trademark & Brand Guidelines
(https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft
trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft
sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.
