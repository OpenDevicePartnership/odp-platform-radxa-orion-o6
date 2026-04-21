# ODP Platform — Bootchain Details

The recommended method for compilation is using a container as outlined in the root README.md file.  The sections below describe the build targets, build outputs, alternative development environments, and hardware details ODP is using for working with the Radxa Orion O6 platform.

All of the details below assume a Linux environment.  A Windows environment can be used to compile, but due to the complicated nature of getting the proper tools installed, it will not be covered in this documentation.  Either a Linux environment or WSL2 for Windows is highly recommended.

## Make Targets

Makefiles are used to build the final output of this repository.  Running `make` or `make all` in the root will invoke each binary and image folder's makefile, create a sub-folder in the `build` directory named after the corresponding binary or image, and place all build remnants along with the final output in that sub-folder.

Executing `make` will download and verify the necessary build tools, collect all pre-compiled binaries, build the platform-specific binaries, then stitch the output firmware binary.  The table below describes each target available in the root Makefile.  For example, the command `make tee` will re-compile the tee firmware binary and `make bootchain` will re-stitch the full bootchain binary with the new tee binary.

| Command | Description |
| --- | --- |
| `make all` | Default target.  Downloads platform build tools, copies pre-built binaries, builds all firmware binaries, then stitches the final bootchain image. |
| `make pre-built` | Copies pre-compiled binary artifacts to the build output directory. |
| `make uefi` | Builds the UEFI firmware binary module. |
| `make tee` | Builds the Trusted Execution Environment (OP-TEE) firmware binary module. |
| `make tf-a` | Builds the Trusted Firmware-A (TF-A/BL31) binary module. |
| `make mem_config` | Builds the memory configuration binary module. |
| `make pm_config` | Builds the power management configuration binary module. |
| `make bootchain` | Stitches all binary module artifacts into the final bootchain firmware images. |
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

## Alternative Development Environments

The `./common/tools/enter-container.sh` script handles building, starting, and entering a container named `odp-orion-o6-build`.  That container can also be used within Visual Studio Code or as a template to set up a native Linux build environment.

### Visual Studio Code Dev Container

Visual Studio Code has a mechanism where it can host [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers).  This is a little more complicated for setup, but provides a single environment to work with Git, modify code, compile, etc., all within an editor that runs within Windows, but has a back-end that resides in WSL to honor things like proper line endings if using WSL.

The link above provides full instructions for setting up this scenario.  It will refer to a Dockerfile and a devcontainer.json file which are both located in this repository in the `.devcontainer/` directory.  But if you are already familiar with VSCode and have it installed, you can quickly enter the remote development environment by performing the following steps.  Once VSCode loads the container, you should be able to open a VSCode terminal and type `make` to compile the code.

#### VS Code in Windows

1. Launch VSCode and click the `Open a Remote Window` button in the bottom left corner.
2. Select `Connect to WSL`, navigate to and open the directory containing this repo.
3. Click the `Open a Remote Window` button a second time.
4. Select `Reopen in Container` to have VSCode reload the project inside the container.

#### VS Code in Linux

1. Launch VSCode and open this repository's folder as the project.
2. Click the `Open a Remote Window` button in the bottom left corner.
3. Select `Reopen in Container` to have VSCode reload the project inside the container.

### Building Outside a Container

The project's [Dockerfile](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/blob/HEAD/.devcontainer/Dockerfile) is the authoritative reference for every tool and dependency required to compile.  The `FROM` tag at the top specifies the expected Operating System and version the file was written against, so if you are using a different distribution, package names may differ.

To set up a native Linux or WSL environment, walk through the Dockerfile and locate sections that have the tag `[Local Build]`.  They document each area necessary to evaluate to properly set up a build environment.

In most places, the entire section can be just copied and pasted into a Linux environment, but Dockerfiles chain commands in each instruction section by using `&&` to minimize image build layers.  A local install is not hampered with image layers, so each command can be run independently in your shell.

The other instructions not tagged by `[Local Build]` are strictly for container builds and should not be needed to set up a local environment.

## Platform Hardware Details

This repository is designed to support the [Radxa Orion O6](https://docs.radxa.com/en/orion/o6) platform using the CIX P1 SoC.  Please refer to the Radxa documentation for detailed baseline information about the platform, setup, schematics, etc.

The following sections then describe additional tools and processes used by the engineers currently engaged in ODP development.  The links are by no means recommended products and are not guaranteed to work, but are listed as a reference to help get set up more quickly.

### SPINOR Flashing

The Orion O6 [Update BIOS Firmware](https://docs.radxa.com/en/orion/o6/low-level-dev/bios) documentation describes a process in which the user can boot into UEFI shell and run an application to write a new firmware binary from a USB drive to the onboard SPINOR.  Due to this method requiring a stable boot on the Orion and how frequently experimental code can cause the system to not boot, the ODP team has taken the approach to remove the SPINOR from the socket and program it in an offline SPINOR writer.

To allow compatibility with multiple platforms, the [DediProg SF100 programmer](https://www.dediprog.com/product/SF100) is being used with a [Backup Boot Flash Module (SO8W)](https://dediprog.com/product/BBF-8W) adapter.  This allows an engineer to remove the chip from the motherboard socket, insert it into the SO8W bracket, flash the binary, then place the updated chip back into the motherboard.

If updating is only seldom performed, or offline programming will only be used for recovery, a generic [CH341A USB programmer](https://www.bing.com/images/search?q=CH341A+programmer) has been proven to work.  Note that the DediProg can auto-detect the required voltage signal level, but most CH341A programmers do not.  Be sure to verify the signaling voltage for your programmer matches the chip supplied with your board before flashing.

Also if the process of removing the chip and flashing in a stand-alone device is used, be sure to verify the orientation of the chip is correct.  SPINOR chips usually define pin 1 by using a dot on the package, but chip vendors have many methods of defining [chip orientation](https://www.bing.com/images/search?q=identify+pin+1+on+a+chip).  And in the programmer, there will be a marker that will define pin 1.

### NVME Drive

The Orion O6 does not come with a pre-installed NVME drive, but does support a PCIe Gen4 x4 m.2 NVMe SSD in 2230, 2242, 2260, and 2280 sizes that can be purchased separately.

The online documentation has instructions for booting and installing the OS from a [USB drive](https://docs.radxa.com/en/orion/o6/getting-started/install-system/nvme-system/no-nvme-reader), and instructions for installing the OS while the NVME drive is inserted into a [USB to M.2 NVMe SSD enclosure](https://docs.radxa.com/en/orion/o6/getting-started/install-system/nvme-system/nvme-reader).  Both methods are used by the ODP team and the [postbuild/os/README.md](https://github.com/radxa/edk2/blob/HEAD/postbuild/os/README.md) file covers building the Windows image with ODP specific changes.

### Serial Debug Logs

Many of the FW images provided by ODP support serial debug messaging or debugging across a UART.  The Orion O6 does not have external UART ports, but it does include UART headers on the motherboard.

By default, the [40-Pin GPIO Header](https://docs.radxa.com/en/orion/o6/hardware-use/hardware-info#40-pin-gpio-header) provides SoC UART3 TX/RX through pins 8 and 10.  In addition, the SoC UART2, SoC UART4, SoC UART5, and EC UART connections are provided through [uart headers](https://docs.radxa.com/en/orion/o6/hardware-use/hardware-info#uart-interfaces).

The ODP team is using an off-the-shelf [USB ft232 UART](https://www.bing.com/search?q=ft232%20UART) adapter set to 3.3V signaling to connect to these pins.  For specifics on which header to use to access UART data from a specific component, please refer to its README.md file.
