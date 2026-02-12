#!/usr/bin/env bash

export  BOLD="\e[1m"
export  NORMAL="\e[0m"
export	RED="\e[31m"
export	GREEN="\e[32m"
export	YELLOW="\e[33m"
export  BLUE="\e[94m"
export  CYAN="\e[36m"

export TOOLCHAIN_WORKSPACE=$PWD
export PATH_OUT="${TOOLCHAIN_WORKSPACE}/output"

export ARM_TOOLCHAIN_ELF="arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf"
export GCC5_AARCH64_PREFIX="${TOOLCHAIN_WORKSPACE}/tools/${ARM_TOOLCHAIN_ELF}/bin/aarch64-none-elf-"
export IASL_PREFIX="${TOOLCHAIN_WORKSPACE}/tools/acpica/generate/unix/bin/"
export PATH_PACKAGE_TOOL="${TOOLCHAIN_WORKSPACE}/common/edk2-non-osi-cix-odp/Platform/CIX/Sky1/PackageTool"
export MBEDTLS_PATH="${TOOLCHAIN_WORKSPACE}/tools/mbedtls"
export PATH_PROJECT="${TOOLCHAIN_WORKSPACE}/uefi/platform"
export PATH_FIRMARES="${PATH_OUT}/Firmwares"

exec_blankfile() {
	for ((i=0;i<$2;i++))
	do
		echo -e -n "\xFF" >> $1
	done
}

build_memcfg(){
    echo -e "BUILD MEMCFG $1 Started."
    local memcfg_dir="${PATH_PROJECT}/mem_config"
    local memcfg_file="memory_config.bin"
    local memcfg_target="$1"

    cd $memcfg_dir

    #compile and generate the memory config with the param: $MEM_CONF_FREQ and $MEM_CONF_CH
    make || exit 1

    cd -

    cp $memcfg_dir/$memcfg_file $memcfg_target

    if [[ -e "${memcfg_target}" ]]; then
        echo -e "${GREEN}BUILD MEMCFG to $memcfg_target Success!!${NORMAL}"
    else
        echo -e "${RED}BUILD MEMCFG to $memcfg_target Failed!!${NORMAL}"
        exit 1
    fi
}

build_pmcfg(){
    echo -e "BUILD PMCFG $1 Started."
    local pmcfg_dir="${PATH_PROJECT}/pm_config"
    local pmcfg_file="csu_pm_config.bin"
    local pmcfg_target="$1"

    cd $pmcfg_dir

    #compile and generate the pm config
    make || exit 1

    cd -

    cp $pmcfg_dir/$pmcfg_file $pmcfg_target

    if [[ -e "${pmcfg_target}" ]]; then
        echo -e "${GREEN}BUILD PMCFG to $pmcfg_target Success!!${NORMAL}"
    else
        echo -e "${RED}BUILD PMCFG to $pmcfg_target Failed!!${NORMAL}"
        exit 1
    fi
}

exec_cix_mkimage() {
    export PATH_OUT_PR="${PATH_OUT}/pr"

    mkdir -p "${PATH_OUT_PR}"
    mkdir -p "${PATH_OUT_PR}/Firmwares"
    mkdir -p "${PATH_OUT_PR}/Keys"
    mkdir -p "${PATH_OUT_PR}/certs"

    local build_key_type=$1
    local path_out_temp
    local flash_all_file_name
    local flash_ota_file_name

    path_out_temp="${PATH_OUT_PR}"
    flash_all_file_name="cix_flash_all"
    flash_ota_file_name="cix_flash_ota"
    cp -f "${PATH_PACKAGE_TOOL}/Firmwares/bootloader1.img" "${path_out_temp}/Firmwares/bootloader1.img"
    cp -f "${PATH_PACKAGE_TOOL}/Firmwares/bootloader2.img" "${path_out_temp}/Firmwares/bootloader2.img"
    cp -f "${PATH_PACKAGE_TOOL}/certs/trusted_key_no.crt" "${path_out_temp}/certs/trusted_key_no.crt"
    cp -f "${PATH_PACKAGE_TOOL}/cert_create_rsa" "${path_out_temp}"

    local path_out_firmwares="${path_out_temp}/Firmwares"

    # copy require files to output
    cp  ${PATH_PACKAGE_TOOL}/Firmwares/*.bin "${path_out_temp}/Firmwares/"
    cp -r "${PATH_PACKAGE_TOOL}/Keys/" "${path_out_temp}"

    exec_blankfile "${path_out_temp}/Firmwares/dummy.bin" 8192

    # build project specific memory config
    echo -e "${GREEN}found project specific memory config ${PATH_PROJECT}/mem_config${NORMAL}"
    build_memcfg "${path_out_firmwares}/memory_config.bin"

    # build project specific pm config
    echo -e "${GREEN}found project specific pm config ${PATH_PROJECT}/pm_config${NORMAL}"
    build_pmcfg "${path_out_firmwares}/csu_pm_config.bin"

    # update project specific low level firmware
    echo -e "${GREEN}found project specific firmware folder ${PATH_PROJECT}/Firmwares/${NORMAL}"
    cp ${PATH_PROJECT}/Firmwares/* ${path_out_firmwares}

	# Copy tools to output
    if [ "$(uname -m)" = "aarch64" ]; then
      cp  "${PATH_PACKAGE_TOOL}/AARCH64/cert_uefi_create_rsa" "${path_out_temp}"
      cp  "${PATH_PACKAGE_TOOL}/AARCH64/cix_package_tool" "${path_out_temp}"
      cp  "${PATH_PACKAGE_TOOL}/AARCH64/fiptool" "${path_out_temp}"
    else
      cp  "${PATH_PACKAGE_TOOL}/X86_64/cert_uefi_create_rsa" "${path_out_temp}"
      cp  "${PATH_PACKAGE_TOOL}/X86_64/cix_package_tool" "${path_out_temp}"
      cp  "${PATH_PACKAGE_TOOL}/X86_64/fiptool" "${path_out_temp}"
    fi
    cp ${PATH_PACKAGE_TOOL}/cix_regen_trusted_key_cert ${path_out_temp}

    cp ${PATH_PACKAGE_TOOL}/spi_flash_config_all.json ${path_out_temp}
    cp ${PATH_PACKAGE_TOOL}/spi_flash_config_ota.json ${path_out_temp}

    # update project specific spi flash layout
    if [[ -e "${PATH_PROJECT}/spi_flash_config_all.json" ]]; then
        echo -e "${GREEN} found project specific ${PATH_PROJECT}/spi_flash_config_all.json${NORMAL}"
        cp ${PATH_PROJECT}/spi_flash_config_all.json ${path_out_temp}
    fi

    if [[ -e "${PATH_PROJECT}/spi_flash_config_ota.json" ]]; then
        echo -e "${GREEN}found project specific ${PATH_PROJECT}/spi_flash_config_ota.json${NORMAL}"
        cp ${PATH_PROJECT}/spi_flash_config_ota.json ${path_out_temp}
    fi

    cd "${path_out_temp}"

	./cert_create_rsa --key-alg rsa --key-size 3072 \
	--hash-alg sha256 --tfw-nvctr 31 \
	--rot-key ${path_out_temp}/Keys/oem_privatekey.pem \
	--trusted-world-key ${path_out_temp}/Keys/oem_privatekey.pem \
	--soc-fw-key ${path_out_temp}/Keys/oem_privatekey.pem \
	--tos-fw-key ${path_out_temp}/Keys/oem_privatekey.pem \
	--trusted-key-cert ${path_out_temp}/certs/trusted_key.crt \
	--soc-fw-key-cert ${path_out_temp}/certs/bl31_fw_key.crt \
	--tos-fw-key-cert ${path_out_temp}/certs/tos_fw_key.crt \
	--soc-fw-cert ${path_out_temp}/certs/bl31_fw_content.crt \
	--tos-fw-cert ${path_out_temp}/certs/tos_fw_cert.crt \
	--soc-fw ${PATH_OUT}/tf-a.bin \
	--tos-fw ${PATH_OUT}/tee.bin

	./fiptool create \
	--soc-fw ${PATH_OUT}/tf-a.bin \
	--tos-fw ${PATH_OUT}/tee.bin \
	--trusted-key-cert ${path_out_temp}/certs/trusted_key.crt \
	--soc-fw-key-cert ${path_out_temp}/certs/bl31_fw_key.crt \
	--tos-fw-key-cert ${path_out_temp}/certs/tos_fw_key.crt \
	--soc-fw-cert ${path_out_temp}/certs/bl31_fw_content.crt \
	--tos-fw-cert ${path_out_temp}/certs/tos_fw_cert.crt \
	${path_out_firmwares}/bootloader2.img

    cd -

    # check bootloader2 image
    if [[ ! -e "${path_out_firmwares}/bootloader2.img" ]]; then
        echo "ERROR: no file ${path_out_firmwares}/bootloader2.img"
        exit 1
    fi

    # Generate bootloader3 image
    cd "${path_out_temp}"

    ./cix_regen_trusted_key_cert -p ${path_out_temp}/Keys/oem_publickey.pem -s ${path_out_temp}/Keys/oem_privatekey.pem -o ${path_out_temp}/certs/trusted_key_no.crt

    ./cert_uefi_create_rsa --key-alg rsa --key-size 3072 --hash-alg sha256 -p --ntfw-nvctr 223 \
        --nt-fw-cert ${path_out_temp}/certs/nt_fw_cert.crt \
        --nt-fw-key-cert ${path_out_temp}/certs/nt_fw_key.crt \
        --nt-fw-key ${path_out_temp}/Keys/oem_privatekey.pem \
        --non-trusted-world-key ${path_out_temp}/Keys/oem_privatekey.pem \
        --nt-fw ${PATH_OUT}/SKY1_BL33_UEFI.fd

    ./fiptool create \
        --trusted-key-cert ${path_out_temp}/certs/trusted_key_no.crt \
        --nt-fw-key-cert ${path_out_temp}/certs/nt_fw_key.crt \
        --nt-fw-cert ${path_out_temp}/certs/nt_fw_cert.crt \
        --nt-fw ${PATH_OUT}/SKY1_BL33_UEFI.fd \
        ${path_out_firmwares}/bootloader3.img
    cd -

    if [[ ! -e "${path_out_firmwares}/bootloader3.img" ]]; then
        echo "ERROR: no file ${path_out_firmwares}/bootloader3.img"
        exit 1
    fi

    # Generate spi flash image
    cd "${path_out_temp}"

	 echo "./cix_package_tool -c spi_flash_config_all.json -o ${flash_all_file_name}.bin"
    ./cix_package_tool -c spi_flash_config_all.json -o ${flash_all_file_name}.bin
    cp ${flash_all_file_name}.bin ${PATH_OUT}/${flash_all_file_name}.bin

    echo "./cix_package_tool -c spi_flash_config_ota.json -O ${flash_ota_file_name}.bin"
    ./cix_package_tool -c spi_flash_config_ota.json -O ${flash_ota_file_name}.bin
    cp ${flash_ota_file_name}.bin ${PATH_OUT}/${flash_ota_file_name}.bin

    cd -

    echo -e "${GREEN}Generate ${PATH_OUT}/${flash_all_file_name}.bin successful!${NORMAL}"

}

# Force a full build each time
rm -rf "${PATH_OUT}"
mkdir -p "${PATH_OUT}"

echo "Build UEFI Project Orion O6"

set -e

./uefi/build.sh
./tee/build.sh
./tf-a/build.sh

cd ${TOOLCHAIN_WORKSPACE}
exec_cix_mkimage
