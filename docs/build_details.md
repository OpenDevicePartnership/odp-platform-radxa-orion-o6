# Build Details

The recommended method for building is using a container as outlined in the root README.md file.  However a containerized environment allows numerous options and helps demonstrate the exact configuration needed for the build process.

## Visual Studio Remote Session in the Dev Container

Visual Studio Code has a mechanism where it can host [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers).  This makes it very easy to modify code, build, work with Git, etc. all within a single editor.

The link above provides full instructions for setting up this scearnio using the docker and json files in the `.devcontainer/` directory.

But if you are already familiar with VSCode and have it installed, you can quickly enter the remote development environment by performing the following steps:

1. Launch VSCode and click the `Open a Remote Window` button in the bottom left
2. If you are in Windows, select `Connect to WSL`, open the directory containing this repo, then click the `Open a Remote Window` button a second time.
3. Select `Reopen in Container` to have VSCode read the devcontainer.json and Dockerfile files to launch a remote development environment in the container.

VSCode will now be setup so you can open a VSCode terminal and run `make` in the root to compile, perform git commands, edit files, etc.

## Building Manually

If you wish to build the FW in a native Linux environment or in WSL without a container, the following steps can be followed:

xxxxxxxxxxxxxxxxxxxxxxxx

> **Note:** The steps below are only needed if you are **not** using a containerized environment.

1. Download the AArch64 bare-metal GNU toolchain (`aarch64-none-elf`):
   <https://developer.arm.com/-/media/files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz>

2. Extract it to `/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf`.

3. Initialize submodules and apply the ACPICA patch:

   ```bash
   git submodule update --init --recursive
   cd uefi/tools/acpica
   git apply ../../../acpica.patch
   ```

## Make Targets

Once inside the build environment, the following `make` targets are available:

| Target | Description |
|---|---|
| `make` | Build everything and produce the final flash images (`cix_flash_all.bin`, `cix_flash_ota.bin`). |
| `make uefi` | Build the UEFI firmware (EDK2). |
| `make tee` | Build the Trusted Execution Environment (OP-TEE). |
| `make tf-a` | Build Trusted Firmware-A (TF-A / BL31). |
| `make mem_config` | Build the memory configuration binary. |
| `make pm_config` | Build the power management configuration binary. |
| `make bootloader2` | Package BL31 + OP-TEE into a signed `bootloader2.img` (requires `tf-a` and `tee`). |
| `make bootloader3` | Package the UEFI image into a signed `bootloader3.img` (requires `uefi`). |
| `make test` | Run UEFI unit tests. |
| `make clean` | Remove all build artifacts. |

Component binaries are placed in `Build/Binaries/`, and final flash images (`cix_flash_all.bin`, `cix_flash_ota.bin`) are written to `Build/` (`$(PATH_BUILD_OUTPUT)`).
