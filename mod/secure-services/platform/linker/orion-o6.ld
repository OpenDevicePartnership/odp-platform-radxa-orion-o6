/*
 * GNU ld linker script defining the memory layout for the Radxa Orion O6 EC
 * Secure Partition image and its FF-A RX/TX buffer region.
 *
 * SPDX-License-Identifier: MIT
 */
MEMORY
{
	image : ORIGIN = 0x81812000, LENGTH = 2M
	rxtx_buf : ORIGIN = 0xA1000000, LENGTH = 8K
}
