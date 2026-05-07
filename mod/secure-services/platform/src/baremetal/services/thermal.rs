//!
//! SPDX-License-Identifier: MIT

use super::passthrough_service::{CommandInfo, PassthroughService};
use crate::baremetal::uart::EcUart;
use ec_service_lib::{Result, Service};
use odp_ffa::{MsgSendDirectReq2, MsgSendDirectResp2};
use uuid::{uuid, Uuid};

pub struct Thermal {
    inner: PassthroughService,
}

impl Thermal {
    pub fn new(uart: EcUart) -> Self {
        const THERMAL_COMMANDS: &[CommandInfo] = &[
            CommandInfo::new(0x1, 1),  // GetTmp,
            CommandInfo::new(0x2, 13), // SetThrs,
            CommandInfo::new(0x3, 1),  // GetThrs,
            CommandInfo::new(0x4, 13), // SetScp,
            CommandInfo::new(0x5, 19), // GetVar,
            CommandInfo::new(0x6, 23), // SetVar,
        ];

        const THERMAL_SERVICE_EID: u8 = 9;

        Self {
            inner: PassthroughService::new(uart, THERMAL_SERVICE_EID, THERMAL_COMMANDS),
        }
    }
}

impl Service for Thermal {
    const UUID: Uuid = uuid!("31f56da7-593c-4d72-a4b3-8fc7171ac073");
    const NAME: &'static str = "Thermal";

    fn ffa_msg_send_direct_req2(&mut self, msg: MsgSendDirectReq2) -> Result<MsgSendDirectResp2> {
        log::info!("Thermal: {:?}", msg);
        self.inner.handle_request(msg)
    }
}
