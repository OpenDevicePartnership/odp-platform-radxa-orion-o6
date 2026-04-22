# Booting Validation OS Image

## Preparing the Windows Validation OS (WinVOS) Image

WinVOS is a pared down Windows OS image that is convenient for basic development while also booting relativley quickly under QEMU.  You'll need access to the [Validation OS Windows 11](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/validation-os-overview?view=windows-11&viewFallbackFrom=windows-11_) VHDX and minimally the following [CAB files](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/validation-os-optional-packages?view=windows-11_) (for keyboard input, connectivity, etc.):

- Microsoft-WinVOS-Connectivity-Package.cab
- Microsoft-WinVOS-Driver-Support-Package.cab
- Microsoft-WinVOS-PnP-Package.cab

To mount and install the CAB files into the VHDX:

1. Mount the VHDX image by double clicking on it and noting the drive letter.  Alternatively, from PowerShell:

    `Mount-VHD -Path "C:\Path\To\ValidationOS.vhdx"`

2. Inject each CAB file using DISM (replace the drive and paths with actual):

    `dism /Image:D:\ /Add-Package /PackagePath:"C:\temp\Microsoft-WinVOS-Connectivity-Package.cab"`

    `dism /Image:D:\ /Add-Package /PackagePath:"C:\temp\Microsoft-WinVOS-Driver-Support-Package.cab"`

    `dism /Image:D:\ /Add-Package /PackagePath:"C:\temp\Microsoft-WinVOS-PnP-Package.cab"`

3. Unmount your VDHX file to make sure it is saved by right-clicking on the drive in File Explorer and selecting Eject.  Alternatively, from PowerShell:

    `Dismount-VHD -Path "C:\Path\To\ValidationOS.vhdx`

## Booting QEMU SBSA to Windows

After you have create a ValidatioOS.vhdx with your required files, simply copy it to the prebuild folder and run
    `make run`

This will generate the qcow2 image from the vhdx and run your BIOS in the parent folder path and boot to a command prompt. Debug output will be displayed on the terminal. Your output display will be redirected to VNC port 5901 by default. You can use and VNC Viewer to open the display `127.0.0.1:5009`. If you installed the packages above you will be able to use mouse and keyboard to interact with the terminal from the OS.

If you want you can force regeneration of the winvos.qcow2 image using
    `make qcow2`

## Connecting with Windbg

By default the serial port is used for debug output. In order to attach with windbg and redirect serial output to an IP port we need to run debug variant.
    `make run_debug`

This exposes a GDB server on `127.0.0.1:5555`. Windbg can be attached on serial port `windbg -k com:ipport=5800,port=127.0.0.1 -v`