# OS Image Installation

This guide covers how to format an NVMe drive using a USB-to-NVMe adapter and install a bootable Windows 11 image to support the Radxa Orion O6.  The process uses standard Windows tools (`diskpart`, `dism`, `bcdedit`), so it will need to be run from a development PC running Windows 11.

## Prerequisites

The Orion O6 does not include a pre-installed NVMe drive but supports PCIe Gen4 x4 M.2 NVMe SSDs in 2230, 2242, 2260, and 2280 sizes.  This example was validated using the following drives and USB to NVME adapters:

### M.2 NVMe Drives

- Crucial P3 Plus 500GB (CT500P3PSSD8)
- SK Hynix HFB1A8M0431A
- SK Hynix HFM256GDGTNG

### NVMe SSD Enclosures

- ACASIS M.2 NVMe & SATA to USB-C
- MAIWO M.2 NVMe to USB Adapter

## Select your Installation WIM Image

A GitHub action routinely builds a Windows Validation OS image that can be downloaded from the repository's [releases](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/releases) and used to boot your test system.  This WIM file image does not include a desktop nor many tools, so you may want to choose a full OS install.  But it is very light-weight and boots quickly for development or testing.

The [Windows 11 for ARM](https://www.microsoft.com/en-us/software-download/windows11arm64) download page provides an installer ISO image that when double clicked to open on a Windows PC, it will be mounted as a storage device with the `sources/install.wim` image you will need below.

Either image can be used but have different names, so they will be referred to as the `WIM` file from here on out.

## Partition and format the NVMe

Install the NVMe drive into the USB-to-NVMe adapter, attach it to your development Windows PC, open an administrator terminal, and run `diskpart`.  The following commands will instruct diskpart to clean, partition, and format the NVMe drive.  The drive letters below were randomly selected and can be any unused letter.

    **WARNING:** The clean command will clean **any** disk selected, even your boot disk.  Be sure to select the proper disk corresponding to your USB adapter.

    ```bat
    list disk               <= Find your USB-to-NVMe adapter in this list
    select disk <number>    <= Replace <number> with the adapter's disk number
    clean                   <= WARNING: This will clean any disk selected, even your boot disk
    convert gpt

    create partition efi size=300
    format fs=fat32 quick label="System"
    assign letter="S"

    create partition primary
    format fs=ntfs quick label="Windows"
    assign letter="W"

    exit                   <= This will exit back into the normal terminal environment
    ```

## Write OS Image to NVMe

Run the following command to write the proper data to the system partition.  If different drive letters were selected above, the letter 'S' needs to be modified.

    ```bat
    bcdboot W:\Windows /s S: /f UEFI
    ```

Run the following command to transfer the data in the WIM file to the Windows partition.  Replace the text `<wim image>` with the actual name/path of the WIM image, and if different drive letters were selected above, the letter 'W' needs to be modified.  

    ```bat
    dism.exe /apply-image /imagefile:<wim image> /index:3 /applydir:W:\
    ```

## OS Boot

The USB-to-NVMe adapter can be removed from the host PC, the NVMe can be installed into the Orion board, and the system will power on and boot into Windows.

Note that these images only contain inbox drivers, so it is expected that devices may appear in DeviceManager without associated drivers.
