//! @file mod.rs
//!
//! Bare-metal module: AArch64 runtime entry point and submodule wiring for
//! the Secure Partition.
//!
//! SPDX-License-Identifier: MIT

mod interrupt;
mod panic;
pub mod services;
pub mod uart;

use aarch64_rt::entry;
use ec_service_lib::SpLogger;

entry!(aarch64_rt_main);
fn aarch64_rt_main(_arg0: u64, _arg1: u64, _arg2: u64, _arg3: u64) -> ! {
    log::set_logger(&SpLogger).unwrap();
    log::set_max_level(log::LevelFilter::Off);
    crate::main();
}
