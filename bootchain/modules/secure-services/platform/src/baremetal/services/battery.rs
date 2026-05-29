//! Battery passthrough service: forwards ACPI battery method calls from the
//! OS to the EC over the UART passthrough transport.
//!
//! SPDX-License-Identifier: MIT
//!

use super::passthrough_service::{CommandInfo, PassthroughService};
use crate::baremetal::uart::EcUart;
use ec_service_lib::{Result, Service};
use odp_ffa::{MsgSendDirectReq2, MsgSendDirectResp2};
use uuid::{uuid, Uuid};

pub struct Battery {
    inner: PassthroughService,
}

impl Battery {
    pub fn new(uart: EcUart) -> Self {
        const BATTERY_COMMANDS: &[CommandInfo] = &[
            CommandInfo::new(0x1, 1),  // GetBix
            CommandInfo::new(0x2, 1),  // GetBst
            CommandInfo::new(0x3, 1),  // GetPsr
            CommandInfo::new(0x4, 1),  // GetPif
            CommandInfo::new(0x5, 1),  // GetBps
            CommandInfo::new(0x6, 2),  // SetBtp
            CommandInfo::new(0x7, 2),  // SetBpt
            CommandInfo::new(0x8, 1),  // GetBpc
            CommandInfo::new(0x9, 2),  // SetBmc
            CommandInfo::new(0xa, 1),  // GetBmd
            CommandInfo::new(0xb, 1),  // GetBct
            CommandInfo::new(0xc, 1),  // GetBtm
            CommandInfo::new(0xd, 2),  // SetBms
            CommandInfo::new(0xe, 2),  // SetBma
            CommandInfo::new(0xf, 1),  // GetSta
            CommandInfo::new(0x80, 1), // SetNfy
        ];

        const BATTERY_SERVICE_EID: u8 = 8;

        Self {
            inner: PassthroughService::new(uart, BATTERY_SERVICE_EID, BATTERY_COMMANDS),
        }
    }
}

impl Service for Battery {
    const UUID: Uuid = uuid!("25cb5207-ac36-427d-aaef-3aa78877d27e");
    const NAME: &'static str = "Battery";

    fn ffa_msg_send_direct_req2(&mut self, msg: MsgSendDirectReq2) -> Result<MsgSendDirectResp2> {
        log::info!("Battery: {:?}", msg);
        self.inner.handle_request(msg)
    }
}
