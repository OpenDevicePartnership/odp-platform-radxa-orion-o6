# HW Used

You can either make a USB thumb drive and boot and install to the NVME or directly use an NVME programmer.  This sample is using the NVME programmer.

The following have been verified to work:
- M.2 NVME drives
  - [Amazon.com: Crucial P3 Plus 500GB CT500P3PSSD8](https://www.amazon.com/dp/B0B25NTRGD?ref_=ppx_hzsearch_conn_dt_b_fed_asin_title_1&th=1)
  - SKHynix HFB1A8M0431A
- NVME SSD Enclosures:
  - [Amazon.com: ACASIS M.2 NVMe & SATA to USB C](https://www.amazon.com/dp/B084ZKLQR8?ref_=ppx_hzsearch_conn_dt_b_fed_asin_title_2&th=1)
  - [Amazon.com: MAIWO M.2 NVMe to USB Adapter](https://www.amazon.com/dp/B0BYD7W96Q?ref=ppx_yo2ov_dt_b_fed_asin_title&th=1)

# Formatting the NVME drive

To setup the NVME drive with the proper partitions, install the NVME drive to your USB dongle, attach it to your dev system, open an admin command prompt, execute `diskpart.exe`, and run the following commands:

```
list disk                                => Lists the disks in the system, find your USB dongle's disk number
select disk <number>                     => Use the number found in the list
list partition                           => Not necessary, just allows you to double confirm the correct drive
clean                                    => Remove any current partitions
convert gpt                              => Use GPT
create partition efi size=300            => Creates an efi partition (auto-selected for the next commands)
format fs=fat32 quick label="System"     => Format efi partition to Fat32
assign letter="S"                        => Maps the efi partition to 'S:\' on your host
create partition primary                 => Creates the primary partition (auto-selected for the next commands)
format fs=ntfs quick label="Windows"     => Format primary partition to NTFS
assign letter="W"                        => Maps the primary partition to 'W:\' on your host
```

# Copy an OS Image to the NVME drive

DISM will be used to install a Windows image to the NVME device.  An image can be obtained by downloading an .iso image locally, double clicking to mount it, then the `install.wim` will be located in the `\sources` directory.

The following image was used for initial testing:

```
\\winbuilds\release\rs_prerelease\29495.1000.251118-1401\arm64fre\iso\iso_client_enterprises_en-us_oem\29495.1000.251118-1401.rs_prerelease_CLIENT_ENTERPRISES_OEM_A64FRE_en-us.iso
```

Run the following commands to install the image onto the primary partition and install the necessary files to the efi partition.  The `/imagefile:install.wim` command line parameter assumes `dism` is being executed from the same folder containing the `install.wim` file.  If not, the file path needs to be updated:

Note: Notice that the command uses the local version of dism.exe. The ISO also has copy of dism.exe in the exact folder that should not be used.

```
c:\Windows\System32\dism.exe /apply-image /imagefile:install.wim /index:3 /applydir:W:\
bcdboot W:\Windows /s S: /f UEFI
```

# Workarounds

There is a known issue with different types of cores on windows.  Orion will need to have the A520 cores disabled so they don't co-exist with A720 cores which is done by limiting proc cores in BCD and disabling them in UEFI setup.

Run the following to setup the OS BCD configuration.  The `numproc` setting is the only necessary setting, the others were added to make development easier:

```
bcdedit /store "S:\EFI\Microsoft\Boot\BCD" /set "{default}" numproc 2
bcdedit /store "S:\EFI\Microsoft\Boot\BCD" /set "{default}" testsigning on
bcdedit /store "S:\EFI\Microsoft\Boot\BCD" /set "{default}" recoveryenabled no
bcdedit /store "S:\EFI\Microsoft\Boot\BCD" /set "{default}" bootstatuspolicy ignoreallfailures
```

Install the NVME back to the board and on the first boot of the Orion platform, enter the UEFI configuration by hitting <esc> on boot, navigate to the CPU configuration page, and use the following settings:

![CPU Configuration Page.png](/.attachments/CPU%20Configuration%20Page-e6b07b66-7c7b-4eeb-b218-8fd091d946a6.png)

Save the configuration, reboot, and Windows should load.  There are numerous bangs in device manager, but the OS should be stable.