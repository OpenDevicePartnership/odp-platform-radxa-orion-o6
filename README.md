# ODP Platform — Radxa Orion O6

## Building with Docker

Docker is the recommended method for building in a containerized environment.

### VS Code Dev Container (Recommended)

1. Open this folder in VS Code.
2. Select **Reopen in Container** when prompted, or run `Dev Containers: Reopen in Container` from the command palette.
3. Open a terminal and run `make`.

### Manual Docker (Linux)

Build the image and launch an interactive shell (uses your host UID/GID so mounted files are owned by you):

```bash
docker build -q -t odp-orion-o6 -f .devcontainer/Dockerfile \
  --build-arg USERNAME=$(whoami) . && \
docker run --rm -it -w /workspace -v "$PWD:/workspace" odp-orion-o6
```

## Building Manually

> **Note:** The steps below are only needed if you are **not** using Docker.

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
