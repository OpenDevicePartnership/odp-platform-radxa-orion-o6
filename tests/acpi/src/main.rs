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
    use logos::Logos;
    use std::path::PathBuf;

    /// Token type for brace-depth tracking in ASL source.
    /// Comments and strings are recognised and ignored during brace counting
    /// so that braces inside them do not affect the depth count.
    #[derive(Logos, Debug, PartialEq)]
    #[logos(skip r"[ \t\r\n\f]+")]
    enum AslToken {
        // Block comment: /* ... */
        #[regex(r"/\*[^*]*(\*[^/][^*]*)*\*/")]
        BlockComment,

        // Line comment: // ... \n
        #[regex(r"//[^\n]*")]
        LineComment,

        // String literal: "..."  (no escapes needed for ASL)
        #[regex(r#""[^"]*""#)]
        StringLiteral,

        #[token("{")]
        OpenBrace,

        #[token("}")]
        CloseBrace,

        // Any other single character – we just skip over it.
        #[regex(r"[^\s{}/\x22]")]
        Other,

        // A lone `/` that doesn't start a comment (single char, lower priority
        // than the multi-char comment regexes).
        #[token("/")]
        Slash,
    }

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

        for candidate in &candidates {
            if candidate.exists() {
                return candidate.clone();
            }
        }

        let tried_paths = candidates
            .iter()
            .map(|p| format!("  - {}", p.display()))
            .collect::<Vec<_>>()
            .join("\n");

        panic!(
            "Cannot locate AcpiPlatfomTables directory.\n\
             Expected to find the ACPI tables submodule under the following paths:\n\
             {tried_paths}"
        );
    }

    /// Read a file from the ACPI tables directory.
    fn read_asl(filename: &str) -> String {
        let path = acpi_tables_dir().join(filename);
        std::fs::read_to_string(&path)
            .unwrap_or_else(|e| panic!("Failed to read {}: {e}", path.display()))
    }

    /// Extract the body of a `Device(<name>){ ... }` block from ASL source,
    /// using brace-depth tracking to find the matching closing brace.
    /// Returns the full block including the `Device(...)` prefix and braces.
    /// Panics if the device is not found.
    fn extract_device_block(source: &str, device_name: &str) -> String {
        // Match "Device(NAME)" or "Device (NAME)" with optional whitespace.
        // NOTE: This initial search uses raw string matching, so a Device()
        // reference inside a comment could produce a false positive. This is
        // acceptable for the current ASL files.
        let patterns = [
            format!("Device({})", device_name),
            format!("Device ({})", device_name),
        ];
        let start = patterns
            .iter()
            .filter_map(|p| source.find(p))
            .min()
            .unwrap_or_else(|| panic!("Device({}) not found in source", device_name));

        // Find the opening brace after Device(NAME)
        let rest = &source[start..];
        let open_brace = rest
            .find('{')
            .unwrap_or_else(|| panic!("No opening brace after Device({})", device_name));

        // Walk forward matching braces using a logos lexer so that braces
        // inside comments and string literals are ignored.
        let mut depth = 0u32;
        let mut end = 0;
        let mut lexer = AslToken::lexer(&rest[open_brace..]);
        while let Some(token) = lexer.next() {
            match token {
                Ok(AslToken::OpenBrace) => depth += 1,
                Ok(AslToken::CloseBrace) => {
                    depth -= 1;
                    if depth == 0 {
                        end = open_brace + lexer.span().end; // include the closing brace
                        break;
                    }
                }
                _ => {}
            }
        }
        assert!(end > 0, "Unmatched braces in Device({})", device_name);
        rest[..end].to_string()
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
        use super::{extract_device_block, read_asl};
        use std::sync::OnceLock;

        /// Cached extraction of the Device(HWMN) block from HardwareMonitor.asl.
        /// Only the content within the HWMN device scope is searched.
        fn read_monitor_source() -> &'static str {
            static CACHE: OnceLock<String> = OnceLock::new();
            CACHE.get_or_init(|| {
                let full = read_asl("HardwareMonitor.asl");
                extract_device_block(&full, "HWMN")
            })
        }

        #[test]
        fn device_node_exists() {
            let src = read_monitor_source();
            assert!(
                src.contains("Device(HWMN)") || src.contains("Device (HWMN)"),
                "HardwareMonitor.asl must define Device(HWMN)"
            );
        }

        #[test]
        fn has_hid() {
            let src = read_monitor_source();
            assert!(src.contains("_HID"), "HWMN device must define _HID");
        }

        #[test]
        fn has_uid() {
            let src = read_monitor_source();
            assert!(src.contains("_UID"), "HWMN device must define _UID");
        }

        #[test]
        fn has_sta_method() {
            let src = read_monitor_source();
            assert!(
                src.contains("Method(_STA)") || src.contains("Method (_STA)"),
                "HWMN device must define _STA method"
            );
        }

        #[test]
        fn has_set_fan_auto_method() {
            let src = read_monitor_source();
            assert!(
                src.contains("Method(SFAT") || src.contains("Method (SFAT"),
                "HWMN device must define SFAT (Set Fan Auto) method"
            );
        }

        #[test]
        fn has_set_fan_mute_method() {
            let src = read_monitor_source();
            assert!(
                src.contains("Method(SFMT") || src.contains("Method (SFMT"),
                "HWMN device must define SFMT (Set Fan Mute) method"
            );
        }

        #[test]
        fn has_set_fan_performance_method() {
            let src = read_monitor_source();
            assert!(
                src.contains("Method(SFPF") || src.contains("Method (SFPF"),
                "HWMN device must define SFPF (Set Fan Performance) method"
            );
        }
    }
}
