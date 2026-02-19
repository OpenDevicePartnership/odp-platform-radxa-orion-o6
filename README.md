# Temporary Placeholder

ODP flavor of the Radxa Orion O6 platform

NOTE:
To build, the GNU toolchain must be downloaded and the acpi must be patched:

Select the AArch64 bare-metal target (aarch64-none-elf)
    https://developer.arm.com/-/media/files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-elf.tar.xz?rev=a05df3001fa34105838e6fba79ee1b23&revision=a05df300-1fa3-4105-838e-6fba79ee1b23&hash=6AC1C332173F612E81ED8B19446DE4E4

Extract the toolchain to directory: "/tools/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf"

use the ./acpica.patch to update the uefi/tools/acpica submodule

```
cd uefi/tools/acpica
git apply ../../../acpica.patch
```

## Building with Docker

Alternatively, you can use Docker to build in a containerized environment:

### VS Code Dev Container (Recommended)

Open this folder in VS Code and select "Reopen in Container" when prompted, or run:
- `Dev Containers: Reopen in Container` from the command palette

The ACPICA patch is automatically applied on container creation.

### Manual Docker

**PowerShell:**
```powershell
# Interactive shell
docker build -q -t odp-orion-o6 -f .devcontainer/Dockerfile . && docker run --rm -it -w /workspace -v "$(($PWD.Path) -replace '\\','/'):/workspace" odp-orion-o6
```

**Linux / macOS:**
```bash
# Interactive shell
docker build -q -t odp-orion-o6 -f .devcontainer/Dockerfile . && docker run --rm -it -w /workspace -v "$PWD:/workspace" odp-orion-o6
