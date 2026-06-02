# Common

## Overview

This directory contains shared resources consumed by multiple modules of the firmware build. Nothing in this
directory produces a standalone build artifact; instead, it provides source packages, platform data, and tooling
that other components reference at build time.

## Contents

| Path | Description |
| --- | --- |
| `cix-edk2-platforms/` | EDK II platform and silicon packages for the CIX Sky1 SoC (submodule) |
| `cix-edk2-non-osi/` | EDK II non-open-source / pre-built binary packages (submodule) |
| `spi_flash_config_all.json` | SPI flash layout and partition configuration |
| `tests/` | Shared test suites (e.g., ACPI table validation) |
| `tools/` | Helper scripts (e.g., GNU toolchain download) |

## Usage

Modules reference this directory through the `ODP_PATH_COMMON` variable defined
in the root Makefile. No direct `make` target exists for this directory.
