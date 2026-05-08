# Memory Configuration

## Overview

This module builds the memory configuration binary (`memory_config.bin`) for the
Radxa Orion O6 platform. The binary contains DDR memory timing and topology
parameters consumed during early boot initialization.

## Source

The configuration source files are located in the shared common tree at:

```text
common/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/mem_config/
```

## Build

This module is invoked from the root Makefile:

```bash
make mem_config
```

## Output

| Artifact | Description |
| --- | --- |
| `memory_config.bin` | Compiled memory configuration binary |

The output binary is placed in the final bootchain binaries directory for
inclusion in the stitched firmware image.
