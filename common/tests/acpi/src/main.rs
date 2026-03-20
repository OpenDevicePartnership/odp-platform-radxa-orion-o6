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

        // Prefer resolving relative to the workspace root (common/tests/acpi -> three levels up).
        if let Some(workspace_root) = manifest_dir
            .parent()
            .and_then(|p| p.parent())
            .and_then(|p| p.parent())
        {
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

    /// Extract the full `<keyword>(<name>){ ... }` block from ASL source,
    /// using brace-depth tracking to find the matching closing brace.
    /// Returns the full block including the prefix and braces.
    /// Panics if the block is not found.
    fn extract_named_block(source: &str, keyword: &str, name: &str) -> String {
        let patterns = [
            format!("{}({})", keyword, name),
            format!("{} ({})", keyword, name),
        ];
        let start = patterns
            .iter()
            .filter_map(|p| source.find(p))
            .min()
            .unwrap_or_else(|| panic!("{}({}) not found in source", keyword, name));

        let rest = &source[start..];
        let open_brace = rest
            .find('{')
            .unwrap_or_else(|| panic!("No opening brace after {}({})", keyword, name));

        let mut depth = 0u32;
        let mut end = 0;
        let mut lexer = AslToken::lexer(&rest[open_brace..]);
        while let Some(token) = lexer.next() {
            match token {
                Ok(AslToken::OpenBrace) => depth += 1,
                Ok(AslToken::CloseBrace) => {
                    depth -= 1;
                    if depth == 0 {
                        end = open_brace + lexer.span().end;
                        break;
                    }
                }
                _ => {}
            }
        }
        assert!(end > 0, "Unmatched braces in {}({})", keyword, name);
        rest[..end].to_string()
    }

    /// Extract the body of a `Device(<name>){ ... }` block from ASL source.
    /// Convenience wrapper around [`extract_named_block`] with `keyword = "Device"`.
    fn extract_device_block(source: &str, device_name: &str) -> String {
        extract_named_block(source, "Device", device_name)
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

    #[test]
    fn ssdt_includes_msft_mptf() {
        let ssdt = read_asl("Ssdt.asl");
        assert!(
            ssdt.contains(r#"include("MSFTThermal.asl")"#),
            "Ssdt.asl must include MSFTThermal.asl"
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

    // -----------------------------------------------------------------------
    // MSFTThermal.asl – device node validation
    // -----------------------------------------------------------------------

    mod msft_mptf {
        use super::{extract_device_block, extract_named_block, read_asl};
        use std::sync::OnceLock;

        /// Cached contents of MSFTThermal.asl.
        fn read_thermal_source() -> &'static str {
            static CACHE: OnceLock<String> = OnceLock::new();
            CACHE.get_or_init(|| read_asl("MSFTThermal.asl"))
        }

        // -- TMPT: Skin temperature sensor (MSFT000A) ----------------------

        mod tmpt {
            use super::*;

            fn device_block() -> &'static str {
                static CACHE: OnceLock<String> = OnceLock::new();
                CACHE.get_or_init(|| extract_device_block(read_thermal_source(), "TMPT"))
            }

            #[test]
            fn device_node_exists() {
                let src = device_block();
                assert!(
                    src.contains("Device(TMPT)") || src.contains("Device (TMPT)"),
                    "MSFTThermal.asl must define Device(TMPT)"
                );
            }

            #[test]
            fn has_hid() {
                let src = device_block();
                assert!(
                    src.contains("MSFT000A"),
                    "TMPT device must have HID MSFT000A"
                );
            }

            #[test]
            fn has_uid() {
                let src = device_block();
                assert!(src.contains("_UID"), "TMPT device must define _UID");
            }

            #[test]
            fn has_sta() {
                let src = device_block();
                assert!(src.contains("_STA"), "TMPT device must define _STA");
            }

            #[test]
            fn has_tmp_method() {
                let src = device_block();
                assert!(
                    src.contains("Method(_TMP") || src.contains("Method (_TMP"),
                    "TMPT device must define _TMP method"
                );
            }

            #[test]
            fn has_dsm_method() {
                let src = device_block();
                assert!(
                    src.contains("Method(_DSM") || src.contains("Method (_DSM"),
                    "TMPT device must define _DSM method"
                );
            }
        }

        // -- CIO1: Customized IO Driver (MSFT000B) -------------------------

        mod cio1 {
            use super::*;

            fn device_block() -> &'static str {
                static CACHE: OnceLock<String> = OnceLock::new();
                CACHE.get_or_init(|| extract_device_block(read_thermal_source(), "CIO1"))
            }

            #[test]
            fn device_node_exists() {
                let src = device_block();
                assert!(
                    src.contains("Device(CIO1)") || src.contains("Device (CIO1)"),
                    "MSFTThermal.asl must define Device(CIO1)"
                );
            }

            #[test]
            fn has_hid() {
                let src = device_block();
                assert!(
                    src.contains("MSFT000B"),
                    "CIO1 device must have HID MSFT000B"
                );
            }

            #[test]
            fn has_uid() {
                let src = device_block();
                assert!(src.contains("_UID"), "CIO1 device must define _UID");
            }

            #[test]
            fn has_sta() {
                let src = device_block();
                assert!(src.contains("_STA"), "CIO1 device must define _STA");
            }

            #[test]
            fn has_dsm_method() {
                let src = device_block();
                assert!(
                    src.contains("Method(_DSM") || src.contains("Method (_DSM"),
                    "CIO1 device must define _DSM method"
                );
            }
        }

        // -- MPCT: MPTFCore Driver (MSFT000D) ------------------------------

        mod mpct {
            use super::*;

            fn device_block() -> &'static str {
                static CACHE: OnceLock<String> = OnceLock::new();
                CACHE.get_or_init(|| extract_device_block(read_thermal_source(), "MPCT"))
            }

            #[test]
            fn device_node_exists() {
                let src = device_block();
                assert!(
                    src.contains("Device(MPCT)") || src.contains("Device (MPCT)"),
                    "MSFTThermal.asl must define Device(MPCT)"
                );
            }

            #[test]
            fn has_hid() {
                let src = device_block();
                assert!(
                    src.contains("MSFT000D"),
                    "MPCT device must have HID MSFT000D"
                );
            }

            #[test]
            fn has_uid() {
                let src = device_block();
                assert!(src.contains("_UID"), "MPCT device must define _UID");
            }

            #[test]
            fn has_sta() {
                let src = device_block();
                assert!(src.contains("_STA"), "MPCT device must define _STA");
            }
        }

        // -- TPOL: Thermal Policy Client (MSFT000E) – ThermalZone ----------

        mod tpol {
            use super::*;

            fn zone_block() -> &'static str {
                static CACHE: OnceLock<String> = OnceLock::new();
                CACHE.get_or_init(|| {
                    extract_named_block(read_thermal_source(), "THERMALZone", "TPOL")
                })
            }

            #[test]
            fn thermal_zone_exists() {
                let src = zone_block();
                assert!(
                    src.contains("THERMALZone(TPOL)") || src.contains("THERMALZone (TPOL)"),
                    "MSFTThermal.asl must define ThermalZone(TPOL)"
                );
            }

            #[test]
            fn has_hid() {
                let src = zone_block();
                assert!(src.contains("MSFT000E"), "TPOL zone must have HID MSFT000E");
            }

            #[test]
            fn has_uid() {
                let src = zone_block();
                assert!(src.contains("_UID"), "TPOL zone must define _UID");
            }

            #[test]
            fn has_sta() {
                let src = zone_block();
                assert!(src.contains("_STA"), "TPOL zone must define _STA");
            }

            #[test]
            fn has_dsm_method() {
                let src = zone_block();
                assert!(
                    src.contains("Method(_DSM") || src.contains("Method (_DSM"),
                    "TPOL zone must define _DSM method"
                );
            }
        }

        // -- PLCD: Power Limit Client Driver (MSFT000F) --------------------

        mod plcd {
            use super::*;

            fn device_block() -> &'static str {
                static CACHE: OnceLock<String> = OnceLock::new();
                CACHE.get_or_init(|| extract_device_block(read_thermal_source(), "PLCD"))
            }

            #[test]
            fn device_node_exists() {
                let src = device_block();
                assert!(
                    src.contains("Device (PLCD)") || src.contains("Device(PLCD)"),
                    "MSFTThermal.asl must define Device(PLCD)"
                );
            }

            #[test]
            fn has_hid() {
                let src = device_block();
                assert!(
                    src.contains("MSFT000F"),
                    "PLCD device must have HID MSFT000F"
                );
            }

            #[test]
            fn has_uid() {
                let src = device_block();
                assert!(src.contains("_UID"), "PLCD device must define _UID");
            }

            #[test]
            fn has_sta() {
                let src = device_block();
                assert!(src.contains("_STA"), "PLCD device must define _STA");
            }
        }

        // -- MPSC: Power Source Client Driver (MSFT0010) -------------------

        mod mpsc {
            use super::*;

            fn device_block() -> &'static str {
                static CACHE: OnceLock<String> = OnceLock::new();
                CACHE.get_or_init(|| extract_device_block(read_thermal_source(), "MPSC"))
            }

            #[test]
            fn device_node_exists() {
                let src = device_block();
                assert!(
                    src.contains("Device(MPSC)") || src.contains("Device (MPSC)"),
                    "MSFTThermal.asl must define Device(MPSC)"
                );
            }

            #[test]
            fn has_hid() {
                let src = device_block();
                assert!(
                    src.contains("MSFT0010"),
                    "MPSC device must have HID MSFT0010"
                );
            }

            #[test]
            fn has_uid() {
                let src = device_block();
                assert!(src.contains("_UID"), "MPSC device must define _UID");
            }

            #[test]
            fn has_sta() {
                let src = device_block();
                assert!(src.contains("_STA"), "MPSC device must define _STA");
            }
        }

        // -- MPSI: Signal IO Client Driver (MSFT0011) ----------------------

        mod mpsi {
            use super::*;

            fn device_block() -> &'static str {
                static CACHE: OnceLock<String> = OnceLock::new();
                CACHE.get_or_init(|| extract_device_block(read_thermal_source(), "MPSI"))
            }

            #[test]
            fn device_node_exists() {
                let src = device_block();
                assert!(
                    src.contains("Device(MPSI)") || src.contains("Device (MPSI)"),
                    "MSFTThermal.asl must define Device(MPSI)"
                );
            }

            #[test]
            fn has_hid() {
                let src = device_block();
                assert!(
                    src.contains("MSFT0011"),
                    "MPSI device must have HID MSFT0011"
                );
            }

            #[test]
            fn has_uid() {
                let src = device_block();
                assert!(src.contains("_UID"), "MPSI device must define _UID");
            }

            #[test]
            fn has_sta() {
                let src = device_block();
                assert!(src.contains("_STA"), "MPSI device must define _STA");
            }
        }

        // -- SOC0: Domain SOC0 (CIXHA037) ----------------------------------

        mod soc0 {
            use super::*;

            fn device_block() -> &'static str {
                static CACHE: OnceLock<String> = OnceLock::new();
                CACHE.get_or_init(|| extract_device_block(read_thermal_source(), "SOC0"))
            }

            #[test]
            fn device_node_exists() {
                let src = device_block();
                assert!(
                    src.contains("Device (SOC0)") || src.contains("Device(SOC0)"),
                    "MSFTThermal.asl must define Device(SOC0)"
                );
            }

            #[test]
            fn has_hid() {
                let src = device_block();
                assert!(
                    src.contains("CIXHA037"),
                    "SOC0 device must have HID CIXHA037"
                );
            }

            #[test]
            fn has_uid() {
                let src = device_block();
                assert!(src.contains("_UID"), "SOC0 device must define _UID");
            }

            #[test]
            fn has_sta() {
                let src = device_block();
                assert!(src.contains("_STA"), "SOC0 device must define _STA");
            }
        }

        // -- MTPT: Power Tracker (MSFT0012) --------------------------------

        mod mtpt {
            use super::*;

            fn device_block() -> &'static str {
                static CACHE: OnceLock<String> = OnceLock::new();
                CACHE.get_or_init(|| extract_device_block(read_thermal_source(), "MTPT"))
            }

            #[test]
            fn device_node_exists() {
                let src = device_block();
                assert!(
                    src.contains("Device (MTPT)") || src.contains("Device(MTPT)"),
                    "MSFTThermal.asl must define Device(MTPT)"
                );
            }

            #[test]
            fn has_hid() {
                let src = device_block();
                assert!(
                    src.contains("MSFT0012"),
                    "MTPT device must have HID MSFT0012"
                );
            }

            #[test]
            fn has_uid() {
                let src = device_block();
                assert!(src.contains("_UID"), "MTPT device must define _UID");
            }

            #[test]
            fn has_sta() {
                let src = device_block();
                assert!(src.contains("_STA"), "MTPT device must define _STA");
            }
        }
    }
}
