# secure-services
This repo contains secure partition code to compile and generate binaries to run in S-EL2 under Hafnium

## Quick Start Guide
To build the EC secure partition for QEMU from this folder run 

`make all`

By default release version is built and output binary can be found at

`Build/qemu-ec-sp.bin`

Running `make all` from the root folder will also rebuild the secure-partition code and link into the BIOS image. 

The DTS and linker addresses must match those defined by TF-A and hafnium images. You can find the addresses listed under the following files.

```
linker/qemu-ec-sp.dts
linker/qemu.ld
```

The GUID's size and offset must match those in the sp_layout.json generated from PlatformBuild.py. The addresses for the secure partitions in the hafnium manifest can be found in the tfa_patches folder under:

`bios/Platforms/QemuSbsaPkg/tfa_patches`
