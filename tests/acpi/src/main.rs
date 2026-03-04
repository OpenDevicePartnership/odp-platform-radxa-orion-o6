// Copyright (c) Microsoft Corporation.
// SPDX-License-Identifier: Apache-2.0

//! ACPI ASL source-level validation tests.
//!
//! These tests parse the raw `.asl` source files and verify that expected
//! device nodes, hardware IDs, and methods are present. This catches
//! accidental deletions or regressions without requiring the full UEFI
//! build toolchain (iasl).

fn main() {
    println!("Run with `cargo test` to execute ACPI validation tests.");
}

#[cfg(test)]
mod tests {
    use std::path::PathBuf;

    /// Root of the ACPI platform tables for Radxa Orion O6.
    fn acpi_tables_dir() -> PathBuf {
        // Path to the ACPI tables submodule relative to the workspace root.
        const ACPI_SUBMODULE_PATH: &str =
            "common/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6/Drivers/AcpiPlatfomTables";

        // Cargo sets CARGO_MANIFEST_DIR to the directory containing this crate's Cargo.toml
        // (tests/acpi). Derive paths from this instead of the process current working directory.
        let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));

        let mut candidates: Vec<PathBuf> = Vec::new();

        // Prefer resolving relative to the workspace root (parent of tests/, i.e. two levels up).
        if let Some(workspace_root) = manifest_dir.parent().and_then(|p| p.parent()) {
            candidates.push(workspace_root.join(ACPI_SUBMODULE_PATH));
        }

        // Also consider the path relative directly to the manifest directory, in case the
        // manifest directory is already the workspace root in some configurations.
        candidates.push(manifest_dir.join(ACPI_SUBMODULE_PATH));

        for candidate in candidates {
            if candidate.exists() {
                return candidate;
            }
        }

        panic!(
            "Cannot locate AcpiPlatfomTables directory. \
             Ensure the ACPI tables submodule is checked out under '{}' \
             relative to the workspace root.",
            ACPI_SUBMODULE_PATH
        );
    }

    /// Read a file from the ACPI tables directory.
    fn read_asl(filename: &str) -> String {
        let path = acpi_tables_dir().join(filename);
        std::fs::read_to_string(&path)
            .unwrap_or_else(|e| panic!("Failed to read {}: {e}", path.display()))
    }

    // -----------------------------------------------------------------------
    // Ssdt.asl – verify HardwareMonitor.asl is included
    // -----------------------------------------------------------------------

    #[test]
    fn ssdt_includes_hardware_monitor() {
        let ssdt = read_asl("Ssdt.asl");
        assert!(
            ssdt.contains(r#"include("HardwareMonitor.asl")"#),
            "Ssdt.asl must include HardwareMonitor.asl"
        );
    }

    // -----------------------------------------------------------------------
    // HardwareMonitor.asl – device node validation
    // -----------------------------------------------------------------------

    mod hardware_monitor {
        use super::read_asl;

        fn source() -> String {
            read_asl("HardwareMonitor.asl")
        }

        #[test]
        fn device_node_exists() {
            let src = source();
            assert!(
                src.contains("Device(HWMN)") || src.contains("Device (HWMN)"),
                "HardwareMonitor.asl must define Device(HWMN)"
            );
        }

        #[test]
        fn has_uid() {
            let src = source();
            assert!(src.contains("_UID"), "HWMN device must define _UID");
        }

        #[test]
        fn has_sta_method() {
            let src = source();
            assert!(
                src.contains("Method(_STA)") || src.contains("Method (_STA)"),
                "HWMN device must define _STA method"
            );
        }

        #[test]
        fn has_set_fan_auto_method() {
            let src = source();
            assert!(
                src.contains("Method(SFAT") || src.contains("Method (SFAT"),
                "HWMN device must define SFAT (Set Fan Auto) method"
            );
        }

        #[test]
        fn has_set_fan_mute_method() {
            let src = source();
            assert!(
                src.contains("Method(SFMT") || src.contains("Method (SFMT"),
                "HWMN device must define SFMT (Set Fan Mute) method"
            );
        }

        #[test]
        fn has_set_fan_performance_method() {
            let src = source();
            assert!(
                src.contains("Method(SFPF") || src.contains("Method (SFPF"),
                "HWMN device must define SFPF (Set Fan Performance) method"
            );
        }
    }
}
