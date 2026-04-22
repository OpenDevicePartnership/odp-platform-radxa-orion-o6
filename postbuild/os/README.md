# ODP Platform — OS Image Creation for NVMe

This guide covers how to format an NVMe drive using a USB enclosure and install a Windows on Arm (WoA) image so the Radxa Orion O6 can boot from it.  The process uses standard Windows tools (`diskpart`, `dism`, `bcdedit`) run from a development PC.

For general information on the Orion O6 NVMe support and alternative installation methods, see the [postbuild/bootchain/README.md](../bootchain/README.md#nvme-drive) and the Radxa online documentation for installing from a [USB drive](https://docs.radxa.com/en/orion/o6/getting-started/install-system/nvme-system/no-nvme-reader) or a [USB to M.2 NVMe SSD enclosure](https://docs.radxa.com/en/orion/o6/getting-started/install-system/nvme-system/nvme-reader).

## Prerequisites

The Orion O6 does not include a pre-installed NVMe drive but supports PCIe Gen4 x4 M.2 NVMe SSDs in 2230, 2242, 2260, and 2280 sizes.  This example was validated using the following drives and USB to NVME adapters:

**M.2 NVMe Drives**

- Crucial P3 Plus 500GB (CT500P3PSSD8)
- SK Hynix HFB1A8M0431A
- SK Hynix HFM256GDGTNG

**NVMe SSD Enclosures**

- ACASIS M.2 NVMe & SATA to USB-C
- MAIWO M.2 NVMe to USB Adapter

## Download and Prepare the Windows Validation OS (WinVOS) Image

WinVOS is a pared down Windows OS image that is convenient for factory environments, but also basic development.  Microsoft Learning has a page for the Windows 11 [Validation OS](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/validation-os-overview?view=windows-11) documentation that contains 2 specific links for downloading and creating bootable media.

The download portion is self explanitory, click the link to accept the license and download the latest Validation OS ISO for Arm64 architecture.

The next section is how to create the bootable Validation OS media.  Click the link  link to create bootable validation OS media.  The first instruction 



## Installation using USB_to_NVME Adapter








## Step 1 — Format the NVMe Drive

Install the NVMe drive into the USB enclosure, attach it to your development PC, then open an **Administrator Command Prompt** and run `diskpart`:

```bat
diskpart
```

Inside the `diskpart` prompt, execute the following commands.  Replace `<number>` with the disk number that corresponds to your USB enclosure (use `list disk` to identify it).

```
list disk
select disk <number>
list partition
clean
convert gpt
create partition efi size=300
format fs=fat32 quick label="System"
assign letter="S"
create partition primary
format fs=ntfs quick label="Windows"
assign letter="W"
exit
```

> **Caution:** Double-check the disk number before running `clean`.  This operation destroys all data on the selected disk.

After these commands complete you will have two partitions:
- **S:\\** — a 300 MB FAT32 EFI System Partition
- **W:\\** — an NTFS partition using the remaining space for the Windows installation

## Step 2 — Apply the Windows Image

Use `dism` to apply the Windows image to the NTFS partition, then `bcdboot` to populate the EFI System Partition with the boot files.

Mount or extract the ISO so that `install.wim` is accessible.  Then, from the directory containing `install.wim`, run:

```bat
c:\Windows\System32\dism.exe /apply-image /imagefile:install.wim /index:3 /applydir:W:\
bcdboot W:\Windows /s S: /f UEFI
```

> **Note:** Use the host system's copy of `dism.exe` (`c:\Windows\System32\dism.exe`).  The ISO may contain its own copy in the `\sources` directory — do **not** use that copy.

If `install.wim` is in a different directory, provide the full path in the `/imagefile:` parameter.

## Step 3 — Apply Workarounds

The Orion O6 SoC contains heterogeneous CPU cores (Arm Cortex-A720 and Cortex-A520).  A known compatibility issue requires the A520 cores to be disabled when running Windows.  This is done in two places: the OS boot configuration and the UEFI setup menu.

### BCD Configuration

From the same Administrator Command Prompt, run the following to configure the boot store on the EFI partition:

```bat
bcdedit /store "S:\EFI\Microsoft\Boot\BCD" /set "{default}" numproc 2
bcdedit /store "S:\EFI\Microsoft\Boot\BCD" /set "{default}" testsigning on
bcdedit /store "S:\EFI\Microsoft\Boot\BCD" /set "{default}" recoveryenabled no
bcdedit /store "S:\EFI\Microsoft\Boot\BCD" /set "{default}" bootstatuspolicy ignoreallfailures
```

| Setting | Purpose |
| --- | --- |
| `numproc 2` | **Required.** Limits the OS to 2 processor cores, avoiding the A520 co-existence issue. |
| `testsigning on` | Enables test-signed drivers for development. |
| `recoveryenabled no` | Disables the recovery environment to simplify development boot flow. |
| `bootstatuspolicy ignoreallfailures` | Prevents automatic recovery mode entry on boot failures. |

### UEFI CPU Configuration

1. Remove the NVMe drive from the USB enclosure and install it in the Orion O6 board.
2. Power on the board and press **Esc** during boot to enter the UEFI setup menu.
3. Navigate to the **CPU Configuration** page.
4. Disable the A520 cores using the on-screen options.
5. Save the configuration and reboot.

## Step 4 — Boot

After applying the UEFI CPU configuration and rebooting, Windows should load from the NVMe drive.  There may be unrecognized devices in Device Manager, but the OS should be stable and usable for development.

## Troubleshooting

| Symptom | Possible Cause | Resolution |
| --- | --- | --- |
| NVMe drive not visible in `diskpart` | Enclosure not recognized or driver issue | Try a different USB port or enclosure; verify the drive is seated properly. |
| BSOD or hang on first boot | A520 cores still active | Verify `numproc 2` was set in BCD **and** A520 cores are disabled in UEFI setup. |
| `dism` fails with access denied | Command Prompt not elevated | Re-open as **Administrator**. |
| Boot loops into recovery | `recoveryenabled` not set | Re-attach the NVMe via USB enclosure and re-run the `bcdedit` commands in Step 3. |
