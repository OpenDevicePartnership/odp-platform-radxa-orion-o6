# Build Details

The recommended method for compilation is using a container as outlined in the root README.md file.  The sections below, however, describe the targets supported in the build infrastructure and how to update a Linux environment to compile without the container.  Windows can be configured to compile, but due to the complicated nature of getting the proper tools installed, it will not be covered in this documentation.

## Make Targets

Makefiles are used to build the final output of this repository.  Running `make` or `make all` in the root will invoke each binary and image folder's makefile, create a sub-folder in the `Build` directory named after the corresponding binary or image, and place all build remnants along with the final output in that sub-folder.

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
| `make clean` | Removes the `Build/` directory and all build remnants. |
| `make distclean` | Performs a `clean` and additionally removes build tool remnants and the downloaded GNU toolchain. |
| `make test` | Runs unit tests for modules that support them. |

The infrastructure also supports two compilation targets, debug (default) and release.

| Command | Description |
| --- | --- |
| `make` | Builds a debug 'flavor' of the repository code |
| `make TARGET=DEBUG` | Builds a debug 'flavor' of the repository code |
| `make TARGET=RELEASE` | Builds a release 'flavor' of the repository code |

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

## Building Outside a Container

The project's [Dockerfile](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/blob/HEAD/.devcontainer/Dockerfile) is the authoritative reference for every tool and dependency required to build.  The `FROM` tag at the top of the file specifies the expected OS and version the file was written against, so if you are using a different distribution, package names may differ.

To set up a native Linux or WSL environment, walk through the Dockerfile and locate sections that have the tag `[Local Build]`.  They document each area necessary to evaluate to properly setup a local build environment.  In most places, the entire section can be just copied and pasted into a Linux environment, but Dockerfiles will chain commands in each instruction section by using `&&` to minimize Docker image layers which is not necessary when installing locally, so each command can be run independently in your shell.

The other instructions not tagged by `[Local Build]` are strictly for container builds and should not be needed to setup a local environment.
