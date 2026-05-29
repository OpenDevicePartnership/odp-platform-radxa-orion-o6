# ODP Platform — OS Image

This directory contains the tools and settings needed to produce an **OS image**, a Windows WIM file that is written to the NVMe drive installed in the Orion O6.

## Environment Setup

Unlike the bootchain, the OS image is staged entirely from a separate Windows host: you build (or download) the WIM on a Windows 11 PC, then partition the NVMe drive and apply the image to it from that same PC using the inbox `diskpart`, `dism`, and `bcdboot` tools.  Once the drive is prepared, it is moved into the Orion O6 for first boot.

To follow the rest of this guide you need:

- **A Windows 11 host PC** with administrator access.  No additional software is required beyond the inbox `diskpart`, `dism`, and `bcdboot` tools.
- **An NVMe drive supported by the Orion O6.**  The board does not ship with one but supports PCIe Gen4 x4 M.2 NVMe SSDs in 2230, 2242, 2260, and 2280 form factors.
- **A USB-to-NVMe adapter** so the Windows host can partition and write the drive before it is installed in the Orion O6.

The drives and adapters listed below have been validated with this guide.  They are not recommendations and are not guaranteed to work, but are provided as a reference to help you get set up more quickly.

| Validated NVMe drives | Validated USB-to-NVMe adapters |
| --- | --- |
| Crucial P3 Plus 500GB (CT500P3PSSD8) | ACASIS M.2 NVMe & SATA to USB-C |
| SK Hynix HFB1A8M0431A | MAIWO M.2 NVMe to USB |
| SK Hynix HFM256GDGTNG | |

## Creating an Installation WIM Image

The GitHub `build_os_image.yml` action is used to create an ODP Validation OS image that can be downloaded from this repository's [releases](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/releases) section and used to boot your test system.  This WIM file image is meant to be light-weight and support boot testing, so it does not include a desktop nor many tools.

If you want a different ODP Validation OS configuration, the WIM can be rebuilt locally on a Windows PC by reproducing what the `build_os_image.yml` workflow does:

1. Download the ARM64 Validation OS ISO from <https://aka.ms/DownloadValidationOS_arm64>.
2. Mount the ISO and note the assigned drive letter (`<drive>` below).
3. From the repository root, run the image generator, pointing it at the package list and policy registry shipped in this folder:

   ```bat
   <drive>:\GenImage\GenImage.cmd ^
       -PackagesList:os_image\O6_config.pkg ^
       -PackagePath:<drive>:\cabs ^
       -ImagePath:<drive>:\ ^
       -RegistryImport:os_image\O6_policy.reg ^
       -OutPath:os_image\build ^
       -wim -NoWait
   ```

4. The generated `os_image\build\ValidationOS-1.wim` is the resulting image.  Adjust `O6_config.pkg` or `O6_policy.reg` to change what ends up in the WIM.

These steps may change over time, so refer to `.github/workflows/build_os_image.yml` if the local build behaves unexpectedly.

If you need a full OS image, it can be downloaded from the [Windows 11 for ARM](https://www.microsoft.com/en-us/software-download/windows11arm64) page.  The provided ISO when double-clicked and mounted on a Windows PC will have a `sources/install.wim` image you will use in the steps below.

Either image can be used.  Their filenames differ, so the rest of this guide refers to whichever you chose as the *WIM file*.

## Build Outputs

A successful local build of the WIM places the output in a `build/` directory created next to this README:

| File | Description |
| --- | --- |
| `build/ValidationOS-1.wim` | The generated ODP Validation OS WIM image, ready to apply to the NVMe drive. |

Inside the release zip published by the `publish_boot_stack.yml` workflow, this file is renamed during staging and appears as `os-image-vYYYY.MM.DD.wim`, where `vYYYY.MM.DD` is the release tag.

## Partition and Format the NVMe

Install the NVMe drive into the USB-to-NVMe adapter, attach it to your development Windows PC, open a Command Prompt or PowerShell window as Administrator, and run `diskpart`.  The following commands will instruct diskpart to clean, partition, and format the NVMe drive.  The drive letters below are examples; substitute any unused letters.

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

Run the following command to apply the WIM file to the Windows partition.  Replace the text `<wim file>` with the actual name/path of the WIM file, and if different drive letters were selected above, the letter `W` needs to be modified.

```bat
dism.exe /apply-image /imagefile:<wim file> /index:3 /applydir:W:\
```

Run the following command to set up the UEFI boot configuration on the system partition.  If different drive letters were selected above, the letter `S` needs to be modified.

```bat
bcdboot W:\Windows /s S: /f UEFI
```

## OS Boot

The USB-to-NVMe adapter can be removed from the host PC and the NVMe drive installed into the Orion board's M.2 slot.  Powering on the system should then boot into Windows.

Note that these images only contain inbox drivers, so it is expected that some devices may appear in Device Manager without associated drivers.
