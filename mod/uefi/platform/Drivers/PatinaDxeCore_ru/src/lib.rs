//! @file lib.rs
//!
//! Platform configuration constants for Radxa O6
//!
//! Defines hardware addresses used by the DXE Core driver. Extracted to a library
//! for testability on the host via `cargo test`.
//!
//! Copyright (c) Microsoft Corporation.
//! SPDX-License-Identifier: MIT

#![cfg_attr(not(test), no_std)]

// GicBases and UartPl011 expect 2 different integer types.
// GicBases are u64 because they are used with the `GenericGic` implementation which expects u64 addresses, even on 32-bit platforms.
// UartPl011 base is usize because the `UartPl011` implementation expects a usize address.

/// UART base address values defined in common/edk2-platforms-cix-odp/Silicon/CIX/Sky1/Include/MemoryMap.h
pub const UART_BASE: usize = 0x040D_0000; // (FCH_BASE + FCH_UART2_SMN_OFFSET)

/// GIC Distributor base address.
pub const GICD_BASE: u64 = 0x0e01_0000;

/// GIC Redistributor base address.
pub const GICR_BASE: u64 = 0x0e09_0000;

/// Maximum size (in bytes) of a formatted log message buffer.
pub const LOG_BUFFER_SIZE: usize = 256;

/// Maps a [`log::Level`] to its string representation.
pub fn log_level_str(level: log::Level) -> &'static str {
    match level {
        log::Level::Error => "ERROR",
        log::Level::Warn => "WARN",
        log::Level::Info => "INFO",
        log::Level::Debug => "DEBUG",
        log::Level::Trace => "TRACE",
    }
}

/// Formats a log message into a fixed-size buffer.
///
/// Returns a [`heapless::String`] containing `[Patina {LEVEL}] message\r\n`.
/// If the formatted message exceeds [`LOG_BUFFER_SIZE`] bytes, the message body
/// is truncated but the trailing `\r\n` is always guaranteed.
pub fn format_log_message(level: &str, args: &core::fmt::Arguments<'_>) -> heapless::String<LOG_BUFFER_SIZE> {
    use core::fmt::Write;
    const CRLF: &str = "\r\n";
    let mut buffer = heapless::String::<LOG_BUFFER_SIZE>::new();
    // Write prefix and message body (may drop args if they exceed buffer capacity, but will never exceed LOG_BUFFER_SIZE)
    let _ = write!(buffer, "[Patina {}] {}", level, args);
    // Ensure room for \r\n by truncating the body if necessary
    let max_body = LOG_BUFFER_SIZE - CRLF.len();
    if buffer.len() > max_body {
        buffer.truncate(max_body);
    }
    let _ = buffer.push_str(CRLF);
    buffer
}

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------
    // Constant validation
    // -------------------------------------------------------

    #[test]
    fn uart_base_is_valid() {
        assert_ne!(UART_BASE, 0, "UART base address must be non-zero");
    }

    #[test]
    fn gic_bases_are_valid() {
        assert_ne!(GICD_BASE, 0, "GICD base must be non-zero");
        assert_ne!(GICR_BASE, 0, "GICR base must be non-zero");

        assert_ne!(GICD_BASE, GICR_BASE, "GICD and GICR bases must be distinct");
    }

    // -------------------------------------------------------
    // Log level string mapping
    // -------------------------------------------------------

    #[test]
    fn log_level_str_covers_all_variants() {
        assert_eq!(log_level_str(log::Level::Error), "ERROR");
        assert_eq!(log_level_str(log::Level::Warn), "WARN");
        assert_eq!(log_level_str(log::Level::Info), "INFO");
        assert_eq!(log_level_str(log::Level::Debug), "DEBUG");
        assert_eq!(log_level_str(log::Level::Trace), "TRACE");
    }

    // -------------------------------------------------------
    // Log message formatting
    // -------------------------------------------------------

    #[test]
    fn format_log_message_basic() {
        let msg = format_log_message("INFO", &format_args!("hello world"));
        assert_eq!(msg.as_str(), "[Patina INFO] hello world\r\n");
    }

    #[test]
    fn format_log_message_with_format_args() {
        let msg = format_log_message("ERROR", &format_args!("code={} msg={}", 99, "fail"));
        assert_eq!(msg.as_str(), "[Patina ERROR] code=99 msg=fail\r\n");
    }

    #[test]
    fn format_log_message_empty_body() {
        let msg = format_log_message("WARN", &format_args!(""));
        assert_eq!(msg.as_str(), "[Patina WARN] \r\n");
    }

    // -------------------------------------------------------
    // Buffer overflow & truncation
    // -------------------------------------------------------

    #[test]
    fn format_log_message_truncates_long_message() {
        // Build a message that exceeds 256 bytes when formatted
        let long = "A".repeat(LOG_BUFFER_SIZE + 24);
        let msg = format_log_message("DEBUG", &format_args!("{}", long));

        // Must not exceed the buffer capacity
        assert!(msg.len() <= LOG_BUFFER_SIZE, "formatted message must not exceed LOG_BUFFER_SIZE bytes");

        // Must still start with the expected prefix
        assert!(msg.starts_with("[Patina DEBUG] "), "truncated message must retain the prefix");

        // Must always end with \r\n even when truncated
        assert!(msg.ends_with("\r\n"), "truncated message must still end with CRLF");
    }

    #[test]
    fn format_log_message_guarantees_crlf_when_args_fills_buffer() {
        // A body so large that prefix + body alone would exceed the buffer
        let long = "X".repeat(LOG_BUFFER_SIZE);
        let msg = format_log_message("ERROR", &format_args!("{}", long));

        assert!(msg.len() <= LOG_BUFFER_SIZE, "message must not exceed buffer capacity");
        assert!(msg.ends_with("\r\n"), "message must end with CRLF regardless of body length");
        assert!(msg.starts_with("[Patina ERROR] "), "message must retain the prefix");
    }

    #[test]
    fn format_log_message_exact_capacity() {
        // "[Patina INFO] " = 13 bytes, "\r\n" = 2 bytes, overhead = 15 bytes
        const OVERHEAD: usize = "[Patina INFO] ".len() + "\r\n".len();
        let body = "B".repeat(LOG_BUFFER_SIZE - OVERHEAD);
        let msg = format_log_message("INFO", &format_args!("{}", body));
        assert_eq!(msg.len(), LOG_BUFFER_SIZE, "message should exactly fill the buffer");
        assert!(msg.ends_with("\r\n"), "message should end with CRLF");
    }
}
