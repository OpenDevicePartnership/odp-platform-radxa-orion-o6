//! @file time_alarm.rs
//!
//! Time/Alarm passthrough service: forwards ACPI time and wake-alarm method
//! calls from the OS to the EC over the UART passthrough transport.
//!
//! SPDX-License-Identifier: MIT

use super::passthrough_service::{CommandInfo, PassthroughService};
use crate::baremetal::uart::EcUart;
use ec_service_lib::{Result, Service};
use odp_ffa::{MsgSendDirectReq2, MsgSendDirectResp2};
use uuid::{uuid, Uuid};

pub struct TimeAlarm {
    inner: PassthroughService,
}

impl TimeAlarm {
    pub fn new(uart: EcUart) -> Self {
        const TIME_ALARM_COMMANDS: &[CommandInfo] = &[
            //      These are currently predicated on the assumption that they'll receive the ACPI method args tightly packed and the command code doesn't take up space in the message.
            //      It also assumes types match the ACPI spec, even though a lot of the arg types are u32s that are semantically booleans or 1-bit enums.
            CommandInfo::new(1, 0),  // GetCapabilities / _GCP
            CommandInfo::new(2, 0),  // GetRealTime / _GRT
            CommandInfo::new(3, 16), // SetRealTime / _SRT
            CommandInfo::new(4, 4),  // GetWakeStatus / _GWS
            CommandInfo::new(5, 4),  // ClearWakeStatus / _CWS
            CommandInfo::new(6, 8),  // SetTimerValue / _STV
            CommandInfo::new(7, 4),  // GetTimerValue / _TIV
            CommandInfo::new(8, 8),  // SetExpiredTimerPolicy / _STP
            CommandInfo::new(9, 4),  // GetExpiredTimerPolicy / _TIP
        ];

        const TIME_ALARM_SERVICE_EID: u8 = 0xB;

        Self {
            inner: PassthroughService::new(uart, TIME_ALARM_SERVICE_EID, TIME_ALARM_COMMANDS),
        }
    }
}

impl Service for TimeAlarm {
    const UUID: Uuid = uuid!("23ea63ed-b593-46ea-b027-8924df88e92f");
    const NAME: &'static str = "TimeAlarm";

    fn ffa_msg_send_direct_req2(&mut self, msg: MsgSendDirectReq2) -> Result<MsgSendDirectResp2> {
        log::info!("TimeAlarm: {:?}", msg);
        self.inner.handle_request(msg)
    }
}
