//! @file main.rs
//!
//! Entry point for the EC secure-services Secure Partition. Provides a
//! bare-metal `no_std` build for the SP and a host-side stub for testing.
//!
//! SPDX-License-Identifier: MIT

#![cfg_attr(target_os = "none", no_std)]
#![cfg_attr(target_os = "none", no_main)]
#![deny(clippy::undocumented_unsafe_blocks)]
#![deny(unsafe_op_in_unsafe_fn)]

#[cfg(target_os = "none")]
mod baremetal;

#[cfg(not(target_os = "none"))]
fn main() {
    println!("qemu-sp stub");
}

#[cfg(target_os = "none")]
fn main() -> ! {
    use ec_service_lib::MessageHandler;
    use odp_ffa::Function;

    log::info!("QEMU Secure Partition - build time: {}", env!("BUILD_TIME"));

    let version = odp_ffa::Version::new().exec().unwrap();
    log::info!("FFA version: {}.{}", version.major(), version.minor());

    let battery = baremetal::services::battery::Battery::new(baremetal::uart::EcUart);
    let thermal = baremetal::services::thermal::Thermal::new(baremetal::uart::EcUart);
    let time_alarm = baremetal::services::time_alarm::TimeAlarm::new(baremetal::uart::EcUart);

    log::info!("Running Version: 1");

    MessageHandler::new()
        .append(battery)
        .append(thermal)
        .append(time_alarm)
        .append(ec_service_lib::services::FwMgmt::new())
        .append(ec_service_lib::services::Notify::new())
        .run_message_loop()
        .expect("Error in run_message_loop");

    unreachable!()
}
