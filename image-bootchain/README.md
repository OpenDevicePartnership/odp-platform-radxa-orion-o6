# ODP Platform — Bootchain Details

The recommended method for compilation is using a container as outlined in the root README.md file.  The sections below describe the targets supported in the build infrastructure, build outputs, container management, alternative development environments, and hardware details for working with the Radxa Orion O6 platform.  Windows can be configured to compile, but due to the complicated nature of getting the proper tools installed, it will not be covered in this documentation.

## Make Targets

Makefiles are used to build the final output of this repository.  Running `make` or `make all` in the root will invoke each binary and image folder's makefile, create a sub-folder in the `build` directory named after the corresponding binary or image, and place all build remnants along with the final output in that sub-folder.

Executing `make` will download and verify the necessary build tools, collect all pre-compiled binaries, build the platform specific binaries, then stitch the output firmware binary.  The table below describes each target available in the root Makefile.  For example, the command `make tee` will re-compile the tee firmware binary and `make image-bootchain` will re-stitch the full bootchain binary with the new tee binary.

| Command | Description |
| --- | --- |
| `make all` | Default target.  Downloads platform build tools, copies pre-built binaries, builds all firmware binaries, then stitches the final bootchain image. |
| `make pre-built` | Copies pre-compiled binary artifacts to the build output directory. |
| `make uefi` | Builds the UEFI firmware binary. |
| `make tee` | Builds the Trusted Execution Environment (OP-TEE) firmware binary. |
| `make tf-a` | Builds the Trusted Firmware-A (TF-A/BL31) binary. |
| `make mem_config` | Builds the memory configuration binary. |
| `make pm_config` | Builds the power management configuration binary. |
| `make image-bootchain` | Stitches all binary artifacts into the final bootchain firmware images. |
| `make toolchain` | Downloads and verifies any toolchains necessary for the build. |
| `make clean` | Removes the `build/` directory and all build remnants. |
| `make distclean` | Performs a `clean` and additionally removes build tool remnants and the downloaded GNU toolchain. |
| `make test` | Runs unit tests for modules that support them. |

The infrastructure also supports two compilation targets, debug (default) and release.

| Command | Description |
| --- | --- |
| `make` | Builds a debug 'flavor' of the repository code |
| `make TARGET=DEBUG` | Builds a debug 'flavor' of the repository code |
| `make TARGET=RELEASE` | Builds a release 'flavor' of the repository code |

## Build Outputs

After a successful `make`, the `build/` directory will contain a sub-folder for each component with its build remnants.  The final firmware images are:

| File | Description |
| --- | --- |
| `build/cix_flash_all.bin` | Full SPINOR flash image containing all firmware components. |
| `build/cix_flash_ota.bin` | OTA-style image for firmware updates. |

Since the container `/workspace` directory is mapped to the repository root, the `build/` directory is accessible both inside and outside the container.

## Container Management

The `./common/tools/enter-container.sh` script handles building, starting, and entering a container named `odp-orion-o6-build`.  That container can also be used within Visual Studio or as a template to setup your linux environment.

### Visual Studio Code Dev Container

Visual Studio Code has a mechanism where it can host [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers).  This is a little more complicated for setup, but provides a single environment to work with Git, modify code, compile, etc., all within a single editor and honoring things like proper line endings if using WSL.

The link above provides full instructions for setting up this scenario using the docker and json files in the `.devcontainer/` directory.  But if you are already familiar with VSCode and have it installed, you can quickly enter the remote development environment by performing the following steps:

[Windows]

1. Launch VSCode and click the `Open a Remote Window` button in the bottom left corner.
2. Select `Connect to WSL`, navigate to and open the directory containing this repo.
3. Click the `Open a Remote Window` button a second time.
4. Select `Reopen in Container`.

[Linux]

1. Launch VSCode and open this repository's folder as the project.
2. Click the `Open a Remote Window` button in the bottom left corner.
3. Select `Reopen in Container`.

VSCode will use the devcontainer.json and Dockerfile files to launch a remote development environment within the container that allows running `make` in a terminal, performing git commands, editing files, etc.

### Building Outside a Container

The project's [Dockerfile](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/blob/HEAD/.devcontainer/Dockerfile) is the authoritative reference for every tool and dependency required to build.  The `FROM` tag at the top of the file specifies the expected OS and version the file was written against, so if you are using a different distribution, package names may differ.

To set up a native Linux or WSL environment, walk through the Dockerfile and locate sections that have the tag `[Local Build]`.  They document each area necessary to evaluate to properly setup a local build environment.  In most places, the entire section can be just copied and pasted into a Linux environment, but Dockerfiles will chain commands in each instruction section by using `&&` to minimize Docker image layers which is not necessary when installing locally, so each command can be run independently in your shell.

The other instructions not tagged by `[Local Build]` are strictly for container builds and should not be needed to setup a local environment.

## Platform Hardware Details

This repository is designed to support the [Radxa Orion O6](https://docs.radxa.com/en/orion/o6) platform using the CIX P1 SoC.  Please refer to the Radxa documentation for detailed information about the platform since this repository documentation focuses on ODP modifications only.

The following sections describe tools and products purchased by the engineers currently engaged in ODP development.  The links are by no means recommended products and are not guaranteed to work, but are listed as a reference to help get set up more quickly.

### SPINOR Flashing

The Orion O6 [Update BIOS Firmware](https://docs.radxa.com/en/orion/o6/low-level-dev/bios) documentation describes a process in which the user can boot into UEFI shell and run an application to write a new firmware binary from a USB drive to the onboard SPINOR.  Due to this method requiring a stable boot on the Orion and how frequently experimental code can cause the system to not boot, the ODP team has taken the approach to remove the SPINOR from the socket and program it in an offline SPINOR writer.

To allow compatibility with multiple platforms, the ODP team is using a [DediProg SF100 programmer](https://www.dediprog.com/product/SF100) with a [Backup Boot Flash Module (SO8W)](https://dediprog.com/product/BBF-8W) adapter.  This allows the engineer to remove the chip from the motherboard, insert it into the SO8W bracket, flash the binary, then place the updated chip back into the motherboard.

If updating is only seldom performed, or offline programming will only be used for recovery, a generic [CH341A USB programmer](https://www.bing.com/search?q=CH341A%20programmer) has been proven to work, but be sure to verify the signaling voltage.  The DediProg can auto-detect levels, but the generic programmer required a 3.3V to 1.8V converter.  Please refer to the chip supplied with your board and the schematic to verify you have the proper voltage set before flashing.

Also if the process of removing the chip and flashing in a stand-alone device is used, be sure to verify the orientation of the chip is correct.  SPINOR chips usually define pin 1 by using a dot on the package, but chip vendors have many methods of defining [chip orientation](https://www.bing.com/search?q=identify%20pin%201%20on%20a%20chip).  And in the programmer, there will be a marker that will define pin 1.

### NVME Drive

The Orion O6 does not come with a pre-installed NVME drive, but does support a PCIe Gen4 x4 m.2 NVMe SSD in 2230, 2242, 2260, and 2280 sizes which will need to be purchased separately.  The online documentation has instructions for booting and installing the OS from a [USB drive](https://docs.radxa.com/en/orion/o6/getting-started/install-system/nvme-system/no-nvme-reader), and instructions for installing the OS while the NVME drive is inserted into a [USB to M.2 NVMe SSD enclosure](https://docs.radxa.com/en/orion/o6/getting-started/install-system/nvme-system/nvme-reader).  Both methods are used by the ODP team and the [image-os component readme](https://github.com/radxa/edk2/blob/HEAD/image-os/README.md) covers building the image that includes all ODP specific changes.

### Serial Debug Logs

Many of the FW images provided by ODP support serial debug messaging or debugging across a UART.  The Orion O6 does not have external UART ports, but it does include UART headers on the motherboard.  By default, the [40-Pin GPIO Header](https://docs.radxa.com/en/orion/o6/hardware-use/hardware-info#40-pin-gpio-header) provides SoC UART3 TX/RX through pins 8 and 10, and SoC UART2, SoC UART4, SoC UART5, and EC UART are provided through [dedicated uart headers](https://docs.radxa.com/en/orion/o6/hardware-use/hardware-info#uart-interfaces).  These are standard debug pins that the ODP team uses a standard [USB ft232 UART](https://www.bing.com/search?q=ft232%20UART) adapter set to 3.3V signaling.  For specifics on which header to use to access UART signals from a FW component, please refer to its specific README to get set up.
