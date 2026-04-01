# Platform Details

This repository is designed to support the [Radxa Orion O6](https://docs.radxa.com/en/orion/o6) platform using the CIX P1 SoC.  Please refer to the link tree on the left for detailed information about the platform since this repository documentation will be focusing on the ODP modifications only.

The following are tools and products purched by the engineers currently engaged in development on the ODP project.  The links below are by no means recommended products and are not guaranteed to work, but are being listed as a reference to help get setup more quickly.

## SPINOR Flashing

   The Orion O6 [Update BIOS Firmware](https://docs.radxa.com/en/orion/o6/low-level-dev/bios) documentation describes a process in which the user can boot into UEFI shell and run an application to write a new firmware binary from the USB drive to the onboard SPINOR.  Due to this method requiring a stable boot on the Orion and how frequently experimental code can cause the system to not boot, the ODP team has taken the approach to remove the SPINOR from the socket and program it in an offline SPINOR writer.

   To allow compatibility with multiple platforms, the ODP team is using a [DediProg SF100 programmer](https://www.dediprog.com/product/SF100) with a [Backup Boot Flash Module (SO8W)](https://dediprog.com/product/BBF-8W) adapter.  This allows the engineer to remove the chip from the motherboard, insert it into the SO8W backet, flash the binary, then place the updated chip back into the motherboard.

   If updating is only seldom performed, or offline programming will only be used for recovery, a generic [CH341A USB programmer](https://www.bing.com/search?q=CH341A%20programmer) has been proven to work, but be sure to verify the signaling voltage.  The DediProg can auto-detect levels, but the generic programmer required a 3.3V to 1.8V converter.  Please refer to the chip supplied with your board and the schematic to verify you have the proper voltage set before flashing.

   Also if the process of removing the chip and flashing in a stand-alone device is used, be sure to verify the orientation of the chip is correct.  SPINOR chips usually define pin 1 by using a dot on the package, but chip vendors have many methods of defining [chip orientation](https://www.bing.com/search?q=identify%20pin%201%20on%20a%20chip).  And in the programmer, there will be a marker that will define pin 1.

## NVME Drive

   The Orion O6 does not come with a pre-installed NVME drive, but does support a PCIe Gen4 x4 m.2 NVMe SSD in 2230, 2242, 2260, and 2280 sizes which will need to be purchased separately.  The online documentation has instructions for booting and installing the OS from a [USB drive](https://docs.radxa.com/en/orion/o6/getting-started/install-system/nvme-system/no-nvme-reader), and instructions for installing the OS while the NVME drive is inserted into a [USB to M.2 NVMe SSD enclosure](https://docs.radxa.com/en/orion/o6/getting-started/install-system/nvme-system/nvme-reader).  Both methods are used by the ODP team and the [image-os component readme](https://github.com/radxa/edk2/blob/HEAD/image-os/README.md) covers building the image that includes all ODP specific changes.

## Serial Debug Logs

   Many of the FW images provided by ODP support serial debug messaging or debugging across a UART.  The Orion O6 does not have external UART ports, but it does include UART headers on the motherboard.  By default, the [40-Pin GPIO Header](https://docs.radxa.com/en/orion/o6/hardware-use/hardware-info#40-pin-gpio-header) provides SoC UART3 TX/RX through pins 8 and 10, and SoC UART2, SoC UART4, SoC UART5, and EC UART are provided through [dedicated uart headers](https://docs.radxa.com/en/orion/o6/hardware-use/hardware-info#uart-interfaces).  These are standard debug pins that the ODP team uses a standard [USB ft232 UART](https://www.bing.com/search?q=ft232%20UART) adapter set to 3.3V signaling.  For specifics on which header to use to access UART signals from a FW component, please refer to its specific README to get setup.
