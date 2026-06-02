# UEFI Firmware

## Overview

This module builds the UEFI firmware (BL33) for the Radxa Orion O6 platform,
based on the TianoCore EDK II framework. The resulting firmware image provides
platform initialization, ACPI tables, driver dispatch, and boot services for the
CIX Sky1 SoC.

## Source

| Directory | Description |
| --- | --- |
| `edk2/` | TianoCore EDK II core (submodule) |
| `platform/` | Platform-specific DSC, FDF, drivers, and Rust modules |

Additional platform packages are referenced from the shared common tree
(`common/cix-edk2-platforms` and `common/cix-edk2-non-osi`).

## Build

This module is built as part of the bootchain `make all` target. It can
also be built directly from the `bootchain/` directory:

```bash
make -C modules/uefi
```

### Key Build Parameters

| Parameter | Value |
| --- | --- |
| Architecture | AArch64 |
| Toolchain | GCC5 |
| Build Type | DEBUG |
| Platform DSC | `platform/O6.dsc` |
| Variable Store | SPI flash |
| Secure MM | StandaloneMM (via OP-TEE) |

### Rust Components

The build includes Rust-based DXE drivers (e.g., `PatinaDxeCore_ru`). Rust code
is checked for formatting (`cargo fmt`) and warnings-as-errors (`cargo clippy`)
before compilation.

## Additional Targets

| Target | Description |
| --- | --- |
| `make test` | Run Rust unit tests on the host |
| `distclean` | Clean EDK II BaseTools build artifacts |

## Output

| Artifact | Description |
| --- | --- |
| `SKY1_BL33_UEFI.fd` | UEFI firmware flash image |

The output binary is placed in the final bootchain binaries directory for
inclusion in the stitched firmware image.
