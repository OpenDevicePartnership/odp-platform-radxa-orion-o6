//! Dedicated UART driver for QEMU<->EC communication used by the Secure
//! Partition's passthrough services.
//!
//! SPDX-License-Identifier: MIT
//!

const UART_BASE: usize = 0x040E_0000;
const UART_DR: usize = UART_BASE;
const UART_FR: usize = UART_BASE + 0x18;

/// Dedicated UART for QEMU<->EC communication.
pub struct EcUart;

impl EcUart {
    #[inline(always)]
    fn write_byte(&self, c: u8) {
        // SAFETY: UART_FR and UART_DR are valid MMIO addresses mapped in the SP manifest.
        unsafe {
            // Wait until TX FIFO is not full (FR bit 5 = TXFF)
            while core::ptr::read_volatile(UART_FR as *const u32) & (1 << 5) != 0 {}

            // Write the byte into the TX FIFO
            core::ptr::write_volatile(UART_DR as *mut u32, c as u32);
        }
    }

    #[inline(always)]
    fn read_byte(&self) -> u8 {
        // SAFETY: UART_FR and UART_DR are valid MMIO addresses mapped in the SP manifest.
        unsafe {
            // Wait until RX FIFO is not empty (FR bit 4 = RXFE)
            while core::ptr::read_volatile(UART_FR as *const u32) & (1 << 4) != 0 {}

            core::ptr::read_volatile(UART_DR as *const u32) as u8
        }
    }

    /// Writes all bytes from `buf` to the UART, blocking per byte as needed.
    pub fn write(&self, buf: &[u8]) {
        for byte in buf {
            self.write_byte(*byte);
        }
    }

    /// Reads bytes from the UART into `buf`, blocking per byte until the buffer is filled.
    pub fn read(&self, buf: &mut [u8]) {
        for byte in buf {
            *byte = self.read_byte();
        }
    }
}
