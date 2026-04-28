# OS Image Installation

This guide covers how to format an NVMe drive using a USB-to-NVMe adapter and install a bootable Windows 11 image to support the Radxa Orion O6.  The process uses standard Windows tools (`diskpart`, `dism`, `bcdedit`), so it will need to be run from a development PC running Windows 11.

## Prerequisites

The Orion O6 does not include a pre-installed NVMe drive but supports PCIe Gen4 x4 M.2 NVMe SSDs in 2230, 2242, 2260, and 2280 sizes.  This example was validated using a `Crucial P3 Plus 500GB (CT500P3PSSD8)`, `SK Hynix HFB1A8M0431A`, and `SK Hynix HFM256GDGTNG` drive, and using an `ACASIS M.2 NVMe & SATA to USB-C` and `MAIWO M.2 NVMe to USB` adapter.

## Select your Installation WIM Image

The GitHub `os_build.yml` action is used to create a Windows Validation OS image that can be downloaded from this repository's [releases](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/releases) section and used to boot your test system.  This WIM file image is meant to be light-weight and support boot testing, so it does not include a desktop nor many tools.

If you want a different Windows Validation OS configuration, see the comment block at the top of `.github/workflows/os_build.yml` for step-by-step instructions on how to run the build locally.

If you need a full OS image, it can be downloaded from the [Windows 11 for ARM](https://www.microsoft.com/en-us/software-download/windows11arm64) page.  The provided ISO when double-clicked and mounted on a Windows PC will have a `sources/install.wim` image you will use in the steps below.

Either image can be used but will have different names, so they will be referred to as the `WIM file` from here on out.

## Partition and format the NVMe

Install the NVMe drive into the USB-to-NVMe adapter, attach it to your development Windows PC, open an administrator terminal, and run `diskpart`.  The following commands will instruct diskpart to clean, partition, and format the NVMe drive.  The drive letters below were randomly selected and can be any unused letter.

**WARNING:** The clean command will clean **any** disk selected, even your boot disk.  Be sure to select the proper disk corresponding to your USB adapter.

```text
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

Run the following command to apply the WIM file to the Windows partition.  Replace the text `<wim file>` with the actual name/path of the WIM file, and if different drive letters were selected above, the letter 'W' needs to be modified.

```bat
dism.exe /apply-image /imagefile:<wim file> /index:3 /applydir:W:\
```

Run the following command to set up the UEFI boot configuration on the system partition.  If different drive letters were selected above, the letter 'S' needs to be modified.

```bat
bcdboot W:\Windows /s S: /f UEFI
```

## OS Boot

The USB-to-NVMe adapter can be removed from the host PC, the NVMe can be installed into the Orion board, and the system will power on and boot into Windows.

Note that these images only contain inbox drivers, so it is expected that devices may appear in DeviceManager without associated drivers.
