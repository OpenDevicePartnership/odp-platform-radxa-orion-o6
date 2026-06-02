# Memory Configuration

## Overview

This module builds the memory configuration binary (`memory_config.bin`) for the
Radxa Orion O6 platform. The binary contains DDR memory timing and topology
parameters consumed during early boot initialization.

## Source

The configuration source files are located in the shared common tree at:

```text
common/cix-edk2-platforms/Platform/Radxa/Orion/O6/mem_config/
```

## Build

This module is built as part of the bootchain `make all` target. It can also be
built directly from the `bootchain/` directory:

```bash
make -C modules/mem_config
```

## Output

| Artifact | Description |
| --- | --- |
| `memory_config.bin` | Compiled memory configuration binary |

The output binary is placed in the final bootchain binaries directory for
inclusion in the stitched firmware image.
