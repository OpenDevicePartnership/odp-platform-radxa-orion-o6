//! DXE Core Sample AARCH64 Binary for QEMU SBSA
//!
//! ## License
//!
//! Copyright (c) Microsoft Corporation.
//!
//! SPDX-License-Identifier: Apache-2.0
//!
#![cfg(all(target_os = "uefi"))]
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
            // Address defined in common/edk2-platforms-cix-odp/Silicon/CIX/Sky1/Include/MemoryMap.h
            uart: UartPl011::new(0x040e_0000),
        }
    }
}

impl log::Log for SimpleLogger {
    fn enabled(&self, _metadata: &log::Metadata) -> bool {
        true
    }

    fn log(&self, record: &log::Record) {
        if self.enabled(record.metadata()) {
            // Simple format: [LEVEL] message
            let level = match record.level() {
                log::Level::Error => "ERROR",
                log::Level::Warn => "WARN",
                log::Level::Info => "INFO",
                log::Level::Debug => "DEBUG",
                log::Level::Trace => "TRACE",
            };
            
            // Write to UART - format the message
            use core::fmt::Write;
            let mut buffer = heapless::String::<256>::new();
            let _ = write!(buffer, "[{}] {}\r\n", level, record.args());
            
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
        unsafe {
            GicBases::new(0x0e01_0000, 0x0e090000)
        }
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
