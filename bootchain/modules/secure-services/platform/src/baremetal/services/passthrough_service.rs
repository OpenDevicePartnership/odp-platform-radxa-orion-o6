//! Generic FF-A direct-message passthrough service that forwards command
//! payloads to the EC over UART using SMBUS/MCTP framing.
//!
//! SPDX-License-Identifier: MIT
//!

use crate::baremetal::uart::EcUart;
use ec_service_lib::Result;
use log::{error, info};
use odp_ffa::{
    DirectMessagePayload, ErrorCode, HasRegisterPayload, MsgSendDirectReq2, MsgSendDirectResp2,
};

const SMBUS_PACKET_HEADER_BYTES: usize = 4;
const MCTP_PACKET_HEADER_BYTES: usize = 4;
const MCTP_MESSAGE_HEADER_BYTES: usize = 1;
const ODP_MESSAGE_HEADER_BYTES: usize = 4;

const FFA_PAYLOAD_REGISTER_COUNT: usize = 14;
const FFA_REGISTER_SIZE_BYTES: usize = core::mem::size_of::<u64>();
const MAX_MESSAGE_SIZE_BYTES: usize = FFA_PAYLOAD_REGISTER_COUNT * FFA_REGISTER_SIZE_BYTES;

const SOC_MCTP_ENTITY_ID: u8 = 0x80;

// This enum should be kept in sync with the AE_* error codes from the acpica project in acexcept.h
// See https://github.com/acpica/acpica/blob/16d14dd4ec9b757c5f15131916b9222aa41ee753/source/include/acexcep.h#L205
#[repr(u32)]
#[allow(dead_code)]
enum AcpiError {
    Ok = 0,
    Error = 0x1,
    NoAcpiTables = 0x2,
    NoNamespace = 0x3,
    NoMemory = 0x4,
    NotFound = 0x5,
    NotExist = 0x6,
    AlreadyExists = 0x7,
    Type = 0x8,
    NullObject = 0x9,
    NullEntry = 0xA,
    BufferOverflow = 0xB,
    StackOverflow = 0xC,
    StackUnderflow = 0xD,
    NotImplemented = 0xE,
    Support = 0xF,
    Limit = 0x10,
    Time = 0x11,
    AcquireDeadlock = 0x12,
    ReleaseDeadlock = 0x13,
    NotAcquired = 0x14,
    AlreadyAcquired = 0x15,
    NoHardwareResponse = 0x16,
    NoGlobalLock = 0x17,
    AbortMethod = 0x18,
    SameHandler = 0x19,
    NoHandler = 0x1A,
    OwnerIdLimit = 0x1B,
    NotConfigured = 0x1C,
    Access = 0x1D,
    IoError = 0x1E,
    NumericOverflow = 0x1F,
    HexOverflow = 0x20,
    DecimalOverflow = 0x21,
    OctalOverflow = 0x22,
    EndOfTable = 0x23,
}

pub struct PassthroughService {
    uart: EcUart,

    destination_eid: u8,

    supported_commands: &'static [CommandInfo],
}

impl PassthroughService {
    pub fn new(
        uart: EcUart,
        destination_eid: u8,
        supported_commands: &'static [CommandInfo],
    ) -> Self {
        Self {
            uart,
            destination_eid,
            supported_commands,
        }
    }
}

pub struct CommandInfo {
    command_code: u8,
    payload_len: usize,
}

impl CommandInfo {
    pub const fn new(command_code: u8, payload_len: usize) -> Self {
        if payload_len > MAX_MESSAGE_SIZE_BYTES {
            panic!("payload_len too large");
        }

        Self {
            command_code,
            payload_len,
        }
    }
}

impl PassthroughService {
    pub fn handle_request(&mut self, msg: MsgSendDirectReq2) -> Result<MsgSendDirectResp2> {
        let cmd = msg.payload().u8_at(0);
        let command_info = self
            .supported_commands
            .iter()
            .find(|c| c.command_code == cmd)
            .ok_or_else(|| {
                error!("Unsupported command 0x{:x}", cmd);
                ErrorCode::InvalidParameters
            })?;

        const COMMAND_CODE_SIZE_BYTES: usize = 1;
        let payload: DirectMessagePayload =
            self.handle_message(&msg, command_info.payload_len + COMMAND_CODE_SIZE_BYTES)?;

        Ok(MsgSendDirectResp2::from_req_with_payload(&msg, payload))
    }
}

// MCTP Packet header
/*
0x02, // Destination Slave
0x0F, // Command Code MCTP 0xf
0x09, // Byte count needs 5 bytes for MCTP header
0x01, // Source Slave
0x01, // Header Version
0x03, // EID for Thermal Service
0x01, // EID for EC Service
0xD3, // Flags = SOM | EOM | SEQ=0x1 | TAG=0x3
*/
impl PassthroughService {
    fn send_cmd(&self, data: &[u8]) -> Result<DirectMessagePayload> {
        // Arbitrary upper bound, good enough to handle all current messages
        const BUFSZ: usize = 256;

        //log::info!("Running send_cmd with data: {:X?}", data);
        self.uart.write(data);

        let mut out_buf = [0u8; BUFSZ];
        let mut out_len = 0;

        // Keep looping until EOM is set
        loop {
            //info!("get_mctp_single");
            let mut buffer = [0u8; BUFSZ];

            // Read the SMBus header (dest addr, command code, byte count, source slave)
            self.uart.read(&mut buffer[..SMBUS_PACKET_HEADER_BYTES]);
            let len = buffer[2] as usize;
            const MAX_MCTP_PACKET_LEN: usize = 69;
            //info!(
            //    "MCTP packet header: {:X?}",
            //    &buffer[..SMBUS_PACKET_HEADER_BYTES]
            //);
            if !(MCTP_PACKET_HEADER_BYTES..=MAX_MCTP_PACKET_LEN).contains(&len) {
                panic!("Invalid MCTP packet length: {}", len);
            }

            // Read the remaining bytes (MCTP header + payload)
            self.uart
                .read(&mut buffer[SMBUS_PACKET_HEADER_BYTES..SMBUS_PACKET_HEADER_BYTES + len]);

            {
                //info!("recv: {:X?}", &buffer[..SMBUS_PACKET_HEADER_BYTES + len]);

                let flags = buffer[7];

                let mut packet_payload_start_index =
                    SMBUS_PACKET_HEADER_BYTES + MCTP_PACKET_HEADER_BYTES;
                // 0x80 is the 'start of message' flag
                if flags & 0x80 != 0 {
                    // Skip ODP header since it's only in the first packet. We're assuming here that there will not ever be more than one pending request
                    packet_payload_start_index +=
                        MCTP_MESSAGE_HEADER_BYTES + ODP_MESSAGE_HEADER_BYTES;
                }

                let out_slice =
                    &buffer[packet_payload_start_index..len + SMBUS_PACKET_HEADER_BYTES];
                out_buf[out_len..out_slice.len() + out_len].copy_from_slice(out_slice);
                out_len += out_slice.len();

                // Check if EOM is set
                if flags & 0x40 != 0 {
                    break;
                }
            }
        }

        Ok(out_buf[0..out_len].iter().cloned().collect())
    }

    fn handle_message(&self, msg: &MsgSendDirectReq2, len: usize) -> Result<DirectMessagePayload> {
        let mut data = [0u8; MAX_MESSAGE_SIZE_BYTES
            + SMBUS_PACKET_HEADER_BYTES
            + MCTP_PACKET_HEADER_BYTES
            + MCTP_MESSAGE_HEADER_BYTES
            + ODP_MESSAGE_HEADER_BYTES];
        data[0] = 0x2; // SMBUS: Destination Slave
        data[1] = 0xF; // SMBUS: Command Code MCTP
        data[2] = (8 + len) as u8; // SMBUS: Byte count (5 bytes MCTP header + payload after msg type)
        data[3] = 0x1; // MCTP: Source Target

        // Above this point is considered "physical medium-specific header" per the MCTP spec section 8.1.
        // The length specified in data[2] includes everything below this point, hence the 8.

        data[4] = 0x1; // MCTP: Header Version
        data[5] = self.destination_eid; // MCTP: Destination EID. // TODO Currently this is redundant with the Service ID field we're using in the ODP packet header. When we figure out where we want it to live, we should change the other one to something sane.
        data[6] = SOC_MCTP_ENTITY_ID; // MCTP: Source EID
        data[7] = 0xD3; // MCTP: Flags = SOM | EOM | SEQ=0x1 | TAG=0x3

        // Below this point is the 'ODP header' - part of the payload of the MCTP packet.
        data[8] = 0x7D; // Message Type: command = 0

        // 0 - 14: discriminant
        // 15: is_error (0 on requests)
        // 16-23: service_id,
        // 24: is_datagram (false, may go away)
        // 25: is_request

        const IS_REQUEST: u8 = 1 << 1;
        const _IS_DATAGRAM: u8 = 1 << 0;
        data[9] = IS_REQUEST; // Message flags.
        data[10] = self.destination_eid; // Service_id
        data[11] = 0; // Command code (high bits) - on the ACPI ASL side, we don't currently support more than 256 command codes, so this is unused.
        data[12] = msg.payload().u8_at(0); // Command code (low bits)

        // The buffer is expected to contain an 8-bit command code followed by an arbitrary payload.
        const PACKET_HEADER_BYTES: usize = SMBUS_PACKET_HEADER_BYTES
            + MCTP_PACKET_HEADER_BYTES
            + MCTP_MESSAGE_HEADER_BYTES
            + ODP_MESSAGE_HEADER_BYTES;
        // Copy over command specific content
        for i in 1..len {
            // -1 to account for the fact that we're starting i at 1 to skip the first element from the msg payload since it's part of the header
            data[i + (PACKET_HEADER_BYTES - 1)] = msg.payload().u8_at(i);
        }

        // Total send length: headers + payload bytes (len-1, since the cmd byte is already in the ODP header)
        let total_len = PACKET_HEADER_BYTES + len - 1;

        let result = self.send_cmd(&data[0..total_len]);

        match result {
            Ok(value) => Ok(value),
            _ => {
                info!("send_cmd failed");
                Ok((AcpiError::Error as u32)
                    .to_le_bytes()
                    .iter()
                    .cloned()
                    .collect())
            }
        }
    }
}
