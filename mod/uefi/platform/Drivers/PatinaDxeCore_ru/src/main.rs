//! @file main.rs
//!
//! Patina DXE Core driver for Radxa O6
//!
//! Copyright (c) Microsoft Corporation.
//! SPDX-License-Identifier: MIT
//!
#![cfg(target_os = "uefi")]
#![no_std]
#![no_main]

use core::{ffi::c_void, panic::PanicInfo};
use patina::serial::uart::UartPl011;
use patina_dxe_core::*;
use patina_ffs_extractors::CompositeSectionExtractor;

//
// Global panic handler
//

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    log::error!("{}", info);
    loop {}
}

//
// Simple logger implementation using UART
//

struct SimpleLogger {
    uart: UartPl011,
}

impl SimpleLogger {
    const fn new() -> Self {
        Self {
            // Configure debug port to UART3 on the 40 pin header
            uart: UartPl011::new(dxe_core::UART_BASE),
        }
    }
}

impl log::Log for SimpleLogger {
    fn enabled(&self, _metadata: &log::Metadata) -> bool {
        true
    }

    fn log(&self, record: &log::Record) {
        if self.enabled(record.metadata()) {
            let level = dxe_core::log_level_str(record.level());
            let buffer = dxe_core::format_log_message(level, record.args());

            // Write each byte to UART
            for byte in buffer.as_bytes() {
                self.uart.write_byte(*byte);
            }
        }
    }

    fn flush(&self) {}
}

static LOGGER: SimpleLogger = SimpleLogger::new();

//
// Configuration
//

struct RadxaO6;

impl MemoryInfo for RadxaO6 {}

impl CpuInfo for RadxaO6 {
    fn gic_bases() -> GicBases {
        unsafe { GicBases::new(dxe_core::GICD_BASE, dxe_core::GICR_BASE) }
    }
}

impl ComponentInfo for RadxaO6 {
    /* Sample TBD
    fn components(mut add: Add<Component>) {
        add.component(patina::test::TestRunner::default().with_callback(|test_name, err_msg| {
            log::error!("Test {} failed: {}", test_name, err_msg);
        }));
    }
    */
}

impl PlatformInfo for RadxaO6 {
    type CpuInfo = Self;
    type MemoryInfo = Self;
    type ComponentInfo = Self;
    type Extractor = CompositeSectionExtractor;
}

static CORE: Core<RadxaO6> = Core::new(CompositeSectionExtractor::new());

//
// Primary entry point
//

#[cfg_attr(target_os = "uefi", unsafe(export_name = "efi_main"))]
pub extern "efiapi" fn _start(physical_hob_list: *const c_void) -> ! {
    // Initialize the logger, ignore errors since they can't be logged
    let _ = log::set_logger(&LOGGER).map(|()| log::set_max_level(log::LevelFilter::Info));
    log::info!("DXE Core Platform Binary Entry");

    // Jump to DXE core entry point which never returns
    CORE.entry_point(physical_hob_list);
}
