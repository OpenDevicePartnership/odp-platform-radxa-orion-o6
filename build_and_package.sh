#!/usr/bin/env bash

export  BOLD="\e[1m"
export  NORMAL="\e[0m"
export	RED="\e[31m"
export	GREEN="\e[32m"
export	YELLOW="\e[33m"
export  BLUE="\e[94m"
export  CYAN="\e[36m"

export ARM_TOOLCHAIN_ELF="arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf"

export TOOLCHAIN_WORKSPACE=$PWD
export PATH_BUILD_OUTPUT="${TOOLCHAIN_WORKSPACE}/Build"

export GCC5_AARCH64_PREFIX="${TOOLCHAIN_WORKSPACE}/tools/${ARM_TOOLCHAIN_ELF}/bin/aarch64-none-elf-"
export IASL_PREFIX="${TOOLCHAIN_WORKSPACE}/tools/acpica/generate/unix/bin/"
export PATH_PACKAGE_TOOL="${TOOLCHAIN_WORKSPACE}/common/edk2-non-osi-cix-odp/Platform/CIX/Sky1/PackageTool"
export PATH_PROJECT="${TOOLCHAIN_WORKSPACE}/common/edk2-platforms-cix-odp/Platform/Radxa/Orion/O6"

exec_blankfile() {
    for ((i=0;i<$2;i++))
    do
        echo -e -n "\xFF" >> $1
    done
}

# Force a full build each time
rm -rf "${PATH_BUILD_OUTPUT}"
mkdir -p "${PATH_BUILD_OUTPUT}"

echo "Build UEFI Project Orion O6"

set -e

./uefi/build.sh
./tee/build.sh
./tf-a/build.sh

cd ${TOOLCHAIN_WORKSPACE}

export PATH_OUT_PR="${PATH_BUILD_OUTPUT}/pr"

mkdir -p "${PATH_OUT_PR}"
mkdir -p "${PATH_OUT_PR}/Firmwares"
mkdir -p "${PATH_OUT_PR}/Keys"
mkdir -p "${PATH_OUT_PR}/certs"

cp -f "${PATH_PACKAGE_TOOL}/Firmwares/bootloader1.img" "${PATH_OUT_PR}/Firmwares/bootloader1.img"
cp -f "${PATH_PACKAGE_TOOL}/Firmwares/bootloader2.img" "${PATH_OUT_PR}/Firmwares/bootloader2.img"
cp -f "${PATH_PACKAGE_TOOL}/certs/trusted_key_no.crt" "${PATH_OUT_PR}/certs/trusted_key_no.crt"
cp -f "${PATH_PACKAGE_TOOL}/cert_create_rsa" "${PATH_OUT_PR}"

path_out_firmwares="${PATH_OUT_PR}/Firmwares"

# copy require files to output
cp  ${PATH_PACKAGE_TOOL}/Firmwares/*.bin "${PATH_OUT_PR}/Firmwares/"
cp -r "${PATH_PACKAGE_TOOL}/Keys/" "${PATH_OUT_PR}"

exec_blankfile ${path_out_firmwares}/dummy.bin 8192
mem_config/build.sh ${path_out_firmwares}/memory_config.bin
pm_config/build.sh "${path_out_firmwares}/csu_pm_config.bin"

# update project specific low level firmware
cp ${PATH_PROJECT}/Firmwares/* ${path_out_firmwares}

# Copy tools to output
if [ "$(uname -m)" = "aarch64" ]; then
    cp  "${PATH_PACKAGE_TOOL}/AARCH64/cert_uefi_create_rsa" "${PATH_OUT_PR}"
    cp  "${PATH_PACKAGE_TOOL}/AARCH64/cix_package_tool" "${PATH_OUT_PR}"
    cp  "${PATH_PACKAGE_TOOL}/AARCH64/fiptool" "${PATH_OUT_PR}"
else
    cp  "${PATH_PACKAGE_TOOL}/X86_64/cert_uefi_create_rsa" "${PATH_OUT_PR}"
    cp  "${PATH_PACKAGE_TOOL}/X86_64/cix_package_tool" "${PATH_OUT_PR}"
    cp  "${PATH_PACKAGE_TOOL}/X86_64/fiptool" "${PATH_OUT_PR}"
fi
cp ${PATH_PACKAGE_TOOL}/cix_regen_trusted_key_cert ${PATH_OUT_PR}

cp ${PATH_PACKAGE_TOOL}/spi_flash_config_all.json ${PATH_OUT_PR}
cp ${PATH_PACKAGE_TOOL}/spi_flash_config_ota.json ${PATH_OUT_PR}

# update project specific spi flash layout
if [[ -e "${PATH_PROJECT}/spi_flash_config_all.json" ]]; then
    echo -e "${GREEN} found project specific ${PATH_PROJECT}/spi_flash_config_all.json${NORMAL}"
    cp ${PATH_PROJECT}/spi_flash_config_all.json ${PATH_OUT_PR}
fi

if [[ -e "${PATH_PROJECT}/spi_flash_config_ota.json" ]]; then
    echo -e "${GREEN}found project specific ${PATH_PROJECT}/spi_flash_config_ota.json${NORMAL}"
    cp ${PATH_PROJECT}/spi_flash_config_ota.json ${PATH_OUT_PR}
fi

cd "${PATH_OUT_PR}"

./cert_create_rsa --key-alg rsa --key-size 3072 \
--hash-alg sha256 --tfw-nvctr 31 \
--rot-key ${PATH_OUT_PR}/Keys/oem_privatekey.pem \
--trusted-world-key ${PATH_OUT_PR}/Keys/oem_privatekey.pem \
--soc-fw-key ${PATH_OUT_PR}/Keys/oem_privatekey.pem \
--tos-fw-key ${PATH_OUT_PR}/Keys/oem_privatekey.pem \
--trusted-key-cert ${PATH_OUT_PR}/certs/trusted_key.crt \
--soc-fw-key-cert ${PATH_OUT_PR}/certs/bl31_fw_key.crt \
--tos-fw-key-cert ${PATH_OUT_PR}/certs/tos_fw_key.crt \
--soc-fw-cert ${PATH_OUT_PR}/certs/bl31_fw_content.crt \
--tos-fw-cert ${PATH_OUT_PR}/certs/tos_fw_cert.crt \
--soc-fw ${PATH_BUILD_OUTPUT}/tf-a.bin \
--tos-fw ${PATH_BUILD_OUTPUT}/tee.bin

./fiptool create \
--soc-fw ${PATH_BUILD_OUTPUT}/tf-a.bin \
--tos-fw ${PATH_BUILD_OUTPUT}/tee.bin \
--trusted-key-cert ${PATH_OUT_PR}/certs/trusted_key.crt \
--soc-fw-key-cert ${PATH_OUT_PR}/certs/bl31_fw_key.crt \
--tos-fw-key-cert ${PATH_OUT_PR}/certs/tos_fw_key.crt \
--soc-fw-cert ${PATH_OUT_PR}/certs/bl31_fw_content.crt \
--tos-fw-cert ${PATH_OUT_PR}/certs/tos_fw_cert.crt \
${path_out_firmwares}/bootloader2.img

cd -

# check bootloader2 image
if [[ ! -e "${path_out_firmwares}/bootloader2.img" ]]; then
    echo "ERROR: no file ${path_out_firmwares}/bootloader2.img"
    exit 1
fi

# Generate bootloader3 image
cd "${PATH_OUT_PR}"

./cix_regen_trusted_key_cert -p ${PATH_OUT_PR}/Keys/oem_publickey.pem -s ${PATH_OUT_PR}/Keys/oem_privatekey.pem -o ${PATH_OUT_PR}/certs/trusted_key_no.crt

./cert_uefi_create_rsa --key-alg rsa --key-size 3072 --hash-alg sha256 -p --ntfw-nvctr 223 \
    --nt-fw-cert ${PATH_OUT_PR}/certs/nt_fw_cert.crt \
    --nt-fw-key-cert ${PATH_OUT_PR}/certs/nt_fw_key.crt \
    --nt-fw-key ${PATH_OUT_PR}/Keys/oem_privatekey.pem \
    --non-trusted-world-key ${PATH_OUT_PR}/Keys/oem_privatekey.pem \
    --nt-fw ${PATH_BUILD_OUTPUT}/SKY1_BL33_UEFI.fd

./fiptool create \
    --trusted-key-cert ${PATH_OUT_PR}/certs/trusted_key_no.crt \
    --nt-fw-key-cert ${PATH_OUT_PR}/certs/nt_fw_key.crt \
    --nt-fw-cert ${PATH_OUT_PR}/certs/nt_fw_cert.crt \
    --nt-fw ${PATH_BUILD_OUTPUT}/SKY1_BL33_UEFI.fd \
    ${path_out_firmwares}/bootloader3.img
cd -

if [[ ! -e "${path_out_firmwares}/bootloader3.img" ]]; then
    echo "ERROR: no file ${path_out_firmwares}/bootloader3.img"
    exit 1
fi

# Generate spi flash image
cd "${PATH_OUT_PR}"

echo "./cix_package_tool -c spi_flash_config_all.json -o cix_flash_all.bin"
./cix_package_tool -c spi_flash_config_all.json -o cix_flash_all.bin
cp cix_flash_all.bin ${PATH_BUILD_OUTPUT}/cix_flash_all.bin

echo "./cix_package_tool -c spi_flash_config_ota.json -O cix_flash_ota.bin"
./cix_package_tool -c spi_flash_config_ota.json -O cix_flash_ota.bin
cp cix_flash_ota.bin ${PATH_BUILD_OUTPUT}/cix_flash_ota.bin

cd -

echo -e "${GREEN}Generate ${PATH_BUILD_OUTPUT}/cix_flash_all.bin successful!${NORMAL}"




