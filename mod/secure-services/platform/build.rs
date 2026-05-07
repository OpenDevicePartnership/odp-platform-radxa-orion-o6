//!
//! SPDX-License-Identifier: MIT

fn main() {
    if std::env::var("CARGO_CFG_TARGET_OS").unwrap() == "none" {
        println!(
            "cargo:rustc-env=BUILD_TIME={}",
            chrono::Utc::now().to_rfc3339()
        );
        println!("cargo:rustc-link-arg=-Tlinker/image.ld");
        println!("cargo:rustc-link-arg=-Tlinker/orion-o6.ld");
        println!("cargo:rerun-if-changed=linker/orion-o6.ld");
        println!("cargo:rerun-if-changed=linker/image.ld");
    }
}
