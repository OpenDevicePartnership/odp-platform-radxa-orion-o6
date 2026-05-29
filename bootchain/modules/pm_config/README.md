# Power Management Configuration

## Overview

This module builds the power management configuration binary
(`csu_pm_config.bin`) for the Radxa Orion O6 platform. The binary contains power
domain and voltage regulator parameters used by the platform's power management
subsystem (CSU).

## Source

The configuration source files are located in the shared common tree at:

```text
common/cix-edk2-platforms/Platform/Radxa/Orion/O6/pm_config/
```

## Build

This module is built as part of the bootchain `make all` target. It can also be
built directly from the `bootchain/` directory:

```bash
make -C modules/pm_config
```

## Output

| Artifact | Description |
| --- | --- |
| `csu_pm_config.bin` | Compiled power management configuration binary |

The output binary is placed in the final bootchain binaries directory for
inclusion in the stitched firmware image.
