# Trusted Firmware-A (TF-A)

## Overview

This module builds ARM Trusted Firmware-A (BL31) for the Radxa Orion O6 platform,
targeting the CIX Sky1 SoC. TF-A provides the EL3 runtime firmware responsible
for secure monitor calls, power state coordination (PSCI), and dispatching into
OP-TEE.

## Source

The TF-A source tree is located in the `arm-trusted-firmware-cix-odp/` submodule
within this directory.

## Build

This module is invoked from the root Makefile and requires the GNU cross-compiler
toolchain:

```bash
make tf-a
```

### Key Build Parameters

| Parameter | Value |
| --- | --- |
| Platform | `sky1` |
| SPD (Secure Payload) | `opteed` (OP-TEE dispatcher) |
| Debug | Enabled |
| Trusted Board Boot | Enabled (ROTPK: development RSA key) |
| SMP | Enabled |

## Output

| Artifact | Description |
| --- | --- |
| `bl31.bin` | TF-A BL31 binary image |
| `bl31.elf` | TF-A BL31 ELF (for debug symbols) |

The output binaries are placed in the final bootchain binaries directory for
inclusion in the stitched firmware image.
