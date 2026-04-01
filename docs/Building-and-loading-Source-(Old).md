# BIOS Source Code

1. To use JTAG with tools like Trace32 for debugging, you need to add compile parameters `-u` or `--unlock` to compile an unlock version of the firmware. For Example:

``` text
   ./build_and_package.sh O6 -u
```
