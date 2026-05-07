//! @file mod.rs
//!
//! This module contains hacked versions of the passthrough services (excluding debug and notification) from:
//! https://github.com/philgweber/n1x-ec-secure-partition/blob/philgweber/notification_hack/secure-partition/src/baremetal/services/
//!
//! These have been modified to directly use UART instead of eSPI as the transport mechanism.
//! Note that the uart-service on the EC still expects SMBUS framing hence why we keep that here.
//!
//! The motivation is this is hacked together for a WinHEC demo, though a cleaner implementation
//! will be pursued long-term.
//!
//! SPDX-License-Identifier: MIT

mod passthrough_service;

pub(crate) mod battery;
pub(crate) mod thermal;
pub(crate) mod time_alarm;
