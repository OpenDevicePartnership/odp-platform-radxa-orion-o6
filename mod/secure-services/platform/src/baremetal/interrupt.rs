//! @file interrupt.rs
//!
//! Hafnium interrupt handler implementation for the QEMU Secure Partition.
//!
//! SPDX-License-Identifier: MIT

use aarch64_haf::{haf_interrupt_handler_impl, HafInterruptHandler};

pub struct QemuInterriptHandler;

impl HafInterruptHandler for QemuInterriptHandler {
    fn handle(&self, haf_interrupt_id: hafnium::InterruptId) {
        log::info!("QEMU Interrupt: {:?}", haf_interrupt_id);
    }
}
haf_interrupt_handler_impl!(static IRQ_HANDLER: QemuInterriptHandler = QemuInterriptHandler);
