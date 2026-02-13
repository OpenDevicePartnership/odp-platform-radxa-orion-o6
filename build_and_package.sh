#!/usr/bin/env bash

set -e

#
# Environment Variables
#

export TOOLCHAIN_WORKSPACE=$PWD
export ARM_TOOLCHAIN_ELF="arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf"
export GCC5_AARCH64_PREFIX="${TOOLCHAIN_WORKSPACE}/tools/${ARM_TOOLCHAIN_ELF}/bin/aarch64-none-elf-"
export PATH_PACKAGE_TOOL="${TOOLCHAIN_WORKSPACE}/common/edk2-non-osi-cix-odp/Platform/CIX/Sky1/PackageTool"
export PATH_CIX_BASE_PROJECT="${TOOLCHAIN_WORKSPACE}/common/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6"
export PATH_BUILD_OUTPUT="${TOOLCHAIN_WORKSPACE}/Build"

mkdir -p "${PATH_BUILD_OUTPUT}"

#
# Copy prebuilt binaries and certificates to the output folder
#

export PATH_BUILD_BOOTCHAIN_BINS="${PATH_BUILD_OUTPUT}/Firmwares"
mkdir -p "${PATH_BUILD_BOOTCHAIN_BINS}"

cp -f "${PATH_PACKAGE_TOOL}/Firmwares/"* "${PATH_BUILD_BOOTCHAIN_BINS}"
cp -f "${PATH_CIX_BASE_PROJECT}/Firmwares/"* "${PATH_BUILD_BOOTCHAIN_BINS}"
head -c 8192 /dev/zero | tr $'\x00' $'\xFF' > "${PATH_BUILD_BOOTCHAIN_BINS}/dummy.bin"

#
# Build individual component binaries
#

./uefi/build.sh
./tee/build.sh     # tee relies on BL32_AP_EFI_STMM.fd being in the bins folder
./tf-a/build.sh
./mem_config/build.sh
./pm_config/build.sh

#
# Generate bootloader2 image
#

"${PATH_PACKAGE_TOOL}/cert_create_rsa" \
    --key-alg rsa \
    --key-size 3072 \
    --hash-alg sha256 \
    --tfw-nvctr 31 \
    --rot-key ${PATH_PACKAGE_TOOL}/Keys/oem_privatekey.pem \
    --trusted-world-key ${PATH_PACKAGE_TOOL}/Keys/oem_privatekey.pem \
    --soc-fw-key ${PATH_PACKAGE_TOOL}/Keys/oem_privatekey.pem \
    --tos-fw-key ${PATH_PACKAGE_TOOL}/Keys/oem_privatekey.pem \
    --trusted-key-cert ${PATH_BUILD_BOOTCHAIN_BINS}/trusted_key.crt \
    --soc-fw-key-cert ${PATH_BUILD_BOOTCHAIN_BINS}/bl31_fw_key.crt \
    --tos-fw-key-cert ${PATH_BUILD_BOOTCHAIN_BINS}/tos_fw_key.crt \
    --soc-fw-cert ${PATH_BUILD_BOOTCHAIN_BINS}/bl31_fw_content.crt \
    --tos-fw-cert ${PATH_BUILD_BOOTCHAIN_BINS}/tos_fw_cert.crt \
    --soc-fw ${PATH_BUILD_BOOTCHAIN_BINS}/bl31.bin \
    --tos-fw ${PATH_BUILD_BOOTCHAIN_BINS}/tee-raw.bin

"${PATH_PACKAGE_TOOL}/X86_64/fiptool" \
    create \
    --soc-fw ${PATH_BUILD_BOOTCHAIN_BINS}/bl31.bin \
    --tos-fw ${PATH_BUILD_BOOTCHAIN_BINS}/tee-raw.bin \
    --trusted-key-cert ${PATH_BUILD_BOOTCHAIN_BINS}/trusted_key.crt \
    --soc-fw-key-cert ${PATH_BUILD_BOOTCHAIN_BINS}/bl31_fw_key.crt \
    --tos-fw-key-cert ${PATH_BUILD_BOOTCHAIN_BINS}/tos_fw_key.crt \
    --soc-fw-cert ${PATH_BUILD_BOOTCHAIN_BINS}/bl31_fw_content.crt \
    --tos-fw-cert ${PATH_BUILD_BOOTCHAIN_BINS}/tos_fw_cert.crt \
    "${PATH_BUILD_BOOTCHAIN_BINS}/bootloader2.img"

#
# Generate bootloader3 image
#

"${PATH_PACKAGE_TOOL}/cix_regen_trusted_key_cert" \
    -p ${PATH_PACKAGE_TOOL}/Keys/oem_publickey.pem \
    -s ${PATH_PACKAGE_TOOL}/Keys/oem_privatekey.pem \
    -o ${PATH_BUILD_BOOTCHAIN_BINS}/trusted_key_no.crt

"${PATH_PACKAGE_TOOL}/X86_64/cert_uefi_create_rsa" \
    --key-alg rsa \
    --key-size 3072 \
    --hash-alg sha256 \
    -p \
    --ntfw-nvctr 223 \
    --nt-fw-cert ${PATH_BUILD_BOOTCHAIN_BINS}/nt_fw_cert.crt \
    --nt-fw-key-cert ${PATH_BUILD_BOOTCHAIN_BINS}/nt_fw_key.crt \
    --nt-fw-key ${PATH_PACKAGE_TOOL}/Keys/oem_privatekey.pem \
    --non-trusted-world-key ${PATH_PACKAGE_TOOL}/Keys/oem_privatekey.pem \
    --nt-fw ${PATH_BUILD_BOOTCHAIN_BINS}/SKY1_BL33_UEFI.fd

"${PATH_PACKAGE_TOOL}/X86_64/fiptool" \
    create \
    --trusted-key-cert ${PATH_BUILD_BOOTCHAIN_BINS}/trusted_key_no.crt \
    --nt-fw-key-cert ${PATH_BUILD_BOOTCHAIN_BINS}/nt_fw_key.crt \
    --nt-fw-cert ${PATH_BUILD_BOOTCHAIN_BINS}/nt_fw_cert.crt \
    --nt-fw ${PATH_BUILD_BOOTCHAIN_BINS}/SKY1_BL33_UEFI.fd \
    ${PATH_BUILD_BOOTCHAIN_BINS}/bootloader3.img

#
# Generate final SPI flash images
#

cd "${PATH_BUILD_BOOTCHAIN_BINS}" # Json files use relative paths from working directory
"${PATH_PACKAGE_TOOL}/X86_64/cix_package_tool" -c "${TOOLCHAIN_WORKSPACE}/common/spi_flash_config_all.json" -o "${PATH_BUILD_OUTPUT}/cix_flash_all.bin"
"${PATH_PACKAGE_TOOL}/X86_64/cix_package_tool" -c "${TOOLCHAIN_WORKSPACE}/common/spi_flash_config_ota.json" -O "${PATH_BUILD_OUTPUT}/cix_flash_ota.bin"
cd -
