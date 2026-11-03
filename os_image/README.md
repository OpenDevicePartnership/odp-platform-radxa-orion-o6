# ODP Platform — OS Image

The ODP Radxa Orion O6 project is focused on booting **Windows**, so this directory provides the instructions and tools needed to create a bootable Windows OS image.  It also assumes the user is running tools from a Windows desktop, either an X64 or AARCH64 host PC is acceptable as both will be able to install the AARCH64 image for the Radxa.

Even though this is targeting Windows, ODP does not purposely block booting of other operating systems which can be downloaded from Radxa's Orion O6 [downloads](https://radxa.com/products/orion/o6/#downloads) page.  If an issue with one of those is encountered, please help us by writing up an issue.

## Environment Setup

Unlike the bootchain, the OS image is staged entirely from a separate Windows host: you download the WIM to a Windows 11 PC, then partition the NVMe drive and apply the image to it from that same PC using the built-in `diskpart`, `dism`, and `bcdboot` tools.  Once the drive is prepared, move it into the Orion O6 for first boot.

To follow the rest of this guide, you need:

- **A Windows 11 host PC** with administrator access.  No additional software is required beyond the built-in Windows tools.
- **An NVMe drive supported by the Orion O6.**  The board does not ship with one but supports PCIe Gen4 x4 M.2 NVMe SSDs in 2230, 2242, 2260, and 2280 form factors.
- **A USB-to-NVMe adapter** so the Windows host can partition and write the drive before it is installed in the Orion O6.

The drives and adapters listed below have been validated with this guide.  They are provided as a reference to help you get set up more quickly, not as recommendations or guarantees of compatibility.

| Validated NVMe drives | Validated USB-to-NVMe adapters |
| --- | --- |
| Crucial P3 Plus 500GB (CT500P3PSSD8) | ACASIS M.2 NVMe & SATA to USB-C |
| SK Hynix HFB1A8M0431A | MAIWO M.2 NVMe to USB |
| SK Hynix HFM256GDGTNG | |

## Obtaining a Windows Installation WIM Image

The [build_os_image.yml](../.github/workflows/build_os_image.yml) workflow creates a [Microsoft WinVOS](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/validation-os-overview?view=windows-11) image that can be downloaded from [GitHub Releases](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/releases).  The `os-image-vYYYY.MM.DD.wim` file located in the release zip file is a lightweight image designed to boot quickly and support testing, so it has only a limited set of tools and does not support a desktop.

If you prefer Windows with a full desktop, download an ISO from the [Windows 11 for Arm64](https://www.microsoft.com/en-us/software-download/windows11arm64) page.  Double-click the ISO in File Explorer to mount it, then use the `sources\install.wim` file in the following steps.

The filenames differ, but either `.wim` image can be used.  The rest of this guide refers to whichever you choose as the *WIM file*.

## Partition and Format the NVMe Drive

Install the NVMe drive in the USB-to-NVMe adapter, attach the adapter to your Windows host PC, and open a PowerShell terminal as Administrator.  Start DiskPart and list the available disks:

```powershell
diskpart
list disk
```

Identify the NVMe drive in the list produced by diskpart and replace the tag `<number>` in the commands below with its disk number.  The commands follow Microsoft's default [UEFI/GPT partition layout](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/configure-uefigpt-based-hard-drive-partitions?view=windows-11) and create the following partitions:

| # | Partition | Size | Format | Letter | Purpose |
| --- | --- | --- | --- | --- | --- |
| 1 | EFI system partition (ESP) | 300 MB | FAT32 | `S` | UEFI boot files.  300 MB is Microsoft's minimum for 4K native drives and also satisfies the 200 MB minimum for 512/512e drives. |
| 2 | Microsoft reserved (MSR) | 16 MB | None | None | Reserved by Windows for partition management.  It cannot store data. |
| 3 | Windows | Remaining space | NTFS | `W` | The operating system. |

The drive letters `S` and `W` are examples and used in steps below.  If other drive letters are used, each command must be updated to be consistent throughout the guide.  And the recovery partition documented in the partition layout guidance was purposely bypassed in this documentation.

While still in `DiskPart`, type the following commands.  **WARNING:** `clean` removes all partitions from the selected disk, even if you select your host PC's boot disk.  Verify the disk number and expected capacity (as a second check) before proceeding.

```diskpart
select disk <number>
clean
convert gpt

create partition efi size=300
format quick fs=fat32 label="System"
assign letter="S"

create partition msr size=16

create partition primary
format quick fs=ntfs label="Windows"
assign letter="W"

list volume
exit
```

The `exit` command returns to the PowerShell terminal with the `S` and `W` drive letters still assigned.

## Write OS Image to NVMe

Continue in the same PowerShell window to copy the proper image to the NVMe drive.  The following steps use the drive letters selected above:

1. Determine which image in the WIM file to install.  Replace the `<wim file path>` tag with the path to the selected *WIM file*.

   ```text
   dism.exe /Get-ImageInfo /ImageFile:"<wim file path>"
   ```

   - **WinVOS image:** Use index `1`.  Validation OS images built for an internal drive (boot from `C:`) use index 1.
   - **Windows 11 desktop image:** The ISO contains several editions.  Use the index whose *Name* matches the edition you are licensed for, such as `Windows 11 Pro`.  The index for a given edition can vary between ISO releases.

2. Apply the WIM file to the Windows partition.  Replace the `<wim file path>` tag with the path to the selected *WIM file* and the `<image index>` tag with the index from the previous step.

   ```text
   dism.exe /Apply-Image /ImageFile:"<wim file path>" /Index:<image index> /ApplyDir:W:\
   ```

3. Install the UEFI boot files on the EFI system partition.  `bcdboot` can also modify the host PC's own boot configuration, so verify that the drive letters refer to the NVMe drive.

   ```text
   bcdboot W:\Windows /s S: /f UEFI
   ```

   > **Secure Boot:** TBD.  Secure Boot support and any required `bcdboot` options are not yet documented.  See [Developer Notes](#developer-notes).

## OS Boot

Once all software has been written to the NVMe drive, remove the assigned drive letters before exiting the PowerShell terminal.

```text
mountvol W: /D
mountvol S: /D
```

Use the **Safely Remove Hardware and Eject Media** icon in the system tray to eject the USB-to-NVMe adapter.  Once confirmed removable, the NVMe drive can be installed in the Orion's M.2 slot to support booting into Windows.  The provided Windows images contain only built-in Windows drivers, so some devices may appear without associated drivers in Device Manager.

## Developer Notes

- A full Windows desktop image may require completing the out-of-box experience (OOBE) which currently requires network access.  As of Q4 2026, the network setup step can be skipped by pressing **Shift+F10** at the screen to open a Command Prompt, then enter `OOBE\BYPASSNRO` to restart OOBE with an option to skip the network step. This workaround however is not guaranteed to be present in later releases.

- **Secure Boot: TBD.**  The bootchain build uses signing keys for the firmware images, but as of Q4 2026 UEFI Secure Boot (key enrollment, enforcement, and the matching OS boot file requirements) has not been fully implemented or documented.  Task [#94](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/issues/94) is tracking that work, including whether `bcdboot` needs the `/bootex` option to use boot files signed with the Windows UEFI CA 2023 certificate.

- The other files in this directory are used by the [build_os_image.yml](../.github/workflows/build_os_image.yml) workflow to create the Microsoft Validation OS (WinVOS) image.  Please refer to the yml file for details.
