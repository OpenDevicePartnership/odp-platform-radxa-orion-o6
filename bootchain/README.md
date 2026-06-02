# ODP Platform — Bootchain

This directory builds the **bootchain**, a firmware image that can be written to the Orion O6's onboard SPI-NOR flash.  It contains firmware modules stitched together into a single binary that boots the platform and hands off to the operating system.

## Environment Setup

The makefiles do rely on environment support, so the fastest way to get set up is to replicate the GitHub workflows by using the repository's Linux container.

### Building Inside a Container

1) If building in Windows, install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) and open a WSL terminal window to provide a Linux environment.  If building in Linux, skip to step 2.

   Note:  The WSL file system can be accessed from Windows by using the path `\\wsl.localhost\...` and the Windows drives can be accessed from WSL by using the path `/mnt/<drive letter>/...`.  However, every access across that boundary introduces delays that can add significant time to the build process.  It is highly recommended to clone the repository into the WSL filesystem and run the build there, only crossing the WSL ↔ Windows boundary (via `\\wsl.localhost\...`) at the end to retrieve the finished build artifacts.

2) Install [Git](https://github.com/git-guides/install-git), clone this repository including **all submodules**, and move to the root.

   ``` bash
   git clone --recurse-submodules https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6.git
   cd odp-platform-radxa-orion-o6
   ```

3) Install a container manager to build and run the development container.  [Docker](https://www.docker.com/get-started/) is often used in corporate environments, but [Podman](https://podman.io/) is an open-source alternative with a Docker-compatible command line interface that will be used in this guide.

4) Build and start the development container, then mount this repository as its workspace.  The enter-container.sh script uses Podman to perform the steps on the first invocation. Subsequent invocations skip the build and re-enter the existing container directly.

   ``` bash
   ./common/tools/enter-container.sh
   ```

5) Once in the container, run `make` from the `/workspace/bootchain` directory.  This builds the bootchain and writes all artifacts, including the final firmware binary, to `/workspace/bootchain/build/`.

   ``` bash
   cd /workspace/bootchain
   make
   ```

Because the container's `/workspace` directory is mapped to the host repository directory, the `build/` directory can be accessed from inside the container, from the host, or via the Windows WSL share described above.

### Native Environment Build

If you'd rather build outside the container, the project's [Dockerfile](../.devcontainer/Dockerfile) is the authoritative reference for every tool and dependency required to compile.  The `FROM` tag at the top specifies the expected operating system and version the file was written against, so if you are using a different distribution, package names may differ.

To set up a native Linux or WSL environment, walk through the Dockerfile and locate sections marked with the tag `[Local Build]`.  They identify each area you need to address when setting up a build environment.  In most places, the entire section can simply be copied and pasted into a Linux environment.  Instructions not tagged with `[Local Build]` are strictly for container builds and should not be needed to set up a local environment.

Note that Dockerfiles chain commands in each instruction section with `&&` to minimize image build layers, but a local install is not hampered by image layers, so each command can be run independently in your shell.

## Make Targets

Running `make` (or `make all`) in this directory creates an output `build/` directory to hold all build artifacts.  It will download and verify the necessary build tools, collect all pre-compiled binaries, build the platform-specific binaries, then stitch them into the final firmware binary.  The table below describes each target available in this Makefile.  Individual modules can be rebuilt by running `make` from their own directory under `modules/`, or with `make -C modules/<name>` from this directory; a subsequent `make all` will re-stitch the bootchain image using the freshly built module binaries.

| Command | Description |
| --- | --- |
| `make all` | Default target.  Downloads platform build tools, copies pre-built binaries, builds all firmware binaries, then stitches the final bootchain image. |
| `make clean` | Removes the `build/` directory and all build artifacts. |
| `make distclean` | Performs a `clean` and additionally removes downloaded build tools. |
| `make test` | Runs unit tests for modules that support them. |

The infrastructure also supports two compilation targets, debug (default) and release.

| Command | Description |
| --- | --- |
| `make` *(or `make target=debug`)* | Builds a debug flavor of the repository code. |
| `make target=release` | Builds a release flavor of the repository code. |

## Build Outputs

A successful build places all artifacts in the `build/` directory created next to this README.  The final firmware image is:

| File | Description |
| --- | --- |
| `build/odp_orion_o6_bootchain.bin` | Full SPI-NOR flash image containing all bootchain firmware components. |
| `build/bootchain/` | Per-module intermediate artifacts (one sub-folder per child module) used to stitch the final image.  Useful for debugging individual modules. |

Inside the release zip published by the `publish_boot_stack.yml` workflow, the final image is renamed during staging and appears as `odp_orion_o6_bootchain-debug-vYYYY.MM.DD.bin` and `odp_orion_o6_bootchain-release-vYYYY.MM.DD.bin` (one for each build target), where `vYYYY.MM.DD` is the release tag.  The release zip also includes the corresponding `bootchain-modules-debug/` and `bootchain-modules-release/` per-module subdirectories alongside each `.bin`.

## Developing in VS Code

Visual Studio Code can run a project inside a container via its [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers) feature.  Setup is a bit more involved, but the result is a single environment for performing Git commands, editing, compiling, terminal commands, and AI coding.  The editor will run natively in Windows or Linux with the back end residing inside the container making use of its environment to compile.

The link above provides full instructions for setting up this scenario.  It refers to a `Dockerfile` and a `devcontainer.json` file, both of which are located in this repository's `.devcontainer/` directory.  If you are already familiar with VS Code and have it installed, you can enter the remote development environment and compile with the platform-specific steps below.

### VS Code in Windows

1. Launch VS Code and click the `Open a Remote Window` button in the bottom-left corner.
2. Select `Connect to WSL`, then navigate to and open the directory containing this repo.
3. Click the `Open a Remote Window` button a second time.
4. Select `Reopen in Container` to reload the project inside the container.
5. Open a terminal in VS Code, `cd bootchain`, and type `make`.

### VS Code in Linux

1. Launch VS Code and open this repository's folder as the project.
2. Click the `Open a Remote Window` button in the bottom-left corner.
3. Select `Reopen in Container` to reload the project inside the container.
4. Open a terminal in VS Code, `cd bootchain`, and type `make`.

## Platform Hardware Details

This repository is designed to support the [Radxa Orion O6](https://docs.radxa.com/en/orion/o6) platform using the CIX P1 SoC.  Please refer to the Radxa documentation for detailed baseline information about the platform, setup, schematics, etc.  The following sections describe additional tools and processes used by the engineers currently engaged in ODP development.  The links are by no means recommended products and are not guaranteed to work, but are listed as a reference to help get set up more quickly.

### SPI-NOR Flashing

The Orion O6 [Update BIOS Firmware](https://docs.radxa.com/en/orion/o6/low-level-dev/bios) documentation describes both an in-system UEFI-shell update method and an [offline programmer method](https://docs.radxa.com/en/orion/o6/low-level-dev/bios#flash-bios-firmware-using-a-programmer-only-when-system-cannot-boot) for the onboard SPI-NOR flash.  Because experimental code frequently leaves the system unable to boot, the ODP team flashes offline by default rather than relying on the UEFI-shell path.  Refer to that page for the general remove/program/reinstall workflow.

On top of that workflow, ODP generally uses a [DediProg SF100 programmer](https://www.dediprog.com/product/SF100) paired with a [Backup Boot Flash Module (SO8W)](https://dediprog.com/product/BBF-8W) socket adapter to flash the chip.  If you only flash occasionally, or cost is a concern, a generic CH341A USB programmer has been proven to work, but most such programmers will not auto-detect the required signaling voltage.  Verify the programmer's signaling voltage matches the SPI-NOR chip supplied with your board before flashing.

### Serial Debug Logs

Many of the firmware images provided by ODP support serial debug messaging or debugging across a UART.  The Orion O6 does not have external UART ports, but it does include UART headers on the motherboard.

By default, the [40-Pin GPIO Header](https://docs.radxa.com/en/orion/o6/hardware-use/hardware-info#40-pin-gpio-header) provides SoC UART3 TX/RX through pins 8 and 10.  In addition, the SoC UART2, SoC UART4, SoC UART5, and EC UART connections are provided through [UART headers](https://docs.radxa.com/en/orion/o6/hardware-use/hardware-info#uart-interfaces).

The ODP team is using an off-the-shelf USB FT232 UART adapter set to 3.3V signaling to connect to these pins.  For specifics on which header to use to access UART data from a specific bootchain module, please refer to its README.md file.
