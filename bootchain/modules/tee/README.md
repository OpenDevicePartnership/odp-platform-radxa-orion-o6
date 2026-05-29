# Trusted Execution Environment (OP-TEE)

## Overview

This module builds OP-TEE OS for the Radxa Orion O6 platform, targeting the CIX
Sky1 SoC. OP-TEE provides the secure-world OS that runs in ARM TrustZone,
hosting trusted applications and the Secure Partition Manager (StandaloneMM) for
UEFI variable storage.

## Source

The OP-TEE source tree is located in the `op-tee-cix-odp/` submodule within this
directory.

## Build

This module is built as part of the bootchain `make all` target. It can also be
built directly from the `bootchain/` directory:

```bash
make -C modules/tee
```

### Key Build Parameters

| Parameter | Value |
| --- | --- |
| Platform | `cix` / `sky1` |
| Architecture | AArch64 (built with `ARCH=arm`, `CFG_ARM64_core=y`) |
| Signing Key | OEM private key (test key by default) |

## Output

| Artifact | Description |
| --- | --- |
| `tee-raw.bin` | OP-TEE OS raw binary image |

The output binary is placed in the final bootchain binaries directory for
inclusion in the stitched firmware image.
