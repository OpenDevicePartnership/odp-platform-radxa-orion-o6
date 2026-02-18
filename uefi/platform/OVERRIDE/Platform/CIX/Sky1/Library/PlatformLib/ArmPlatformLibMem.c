/** @file
 *
 *  Copyright 2024 Cix Technology Group Co., Ltd. All Rights Reserved.
 *  Copyright (c) 2019, Pete Batard <pete@akeo.ie>
 *  Copyright (c) 2017-2018, Andrey Warkentin <andrey.warkentin@gmail.com>
 *  Copyright (c) 2014, Linaro Limited. All rights reserved.
 *  Copyright (c) 2013-2018, ARM Limited. All rights reserved.
 *
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 **/

#include <Library/ArmPlatformLib.h>
#include <Library/DebugLib.h>
#include <Library/MemoryAllocationLib.h>
#include <Library/PcdLib.h>
#include <Library/HobLib.h>
#include <Library/ShMemLib.h>
#include <Protocol/MemOutputBuffer.h>

extern UINT64  mSystemMemoryEnd;

// The total number of descriptors, including the final "end-of-table" descriptor.
#define MAX_VIRTUAL_MEMORY_MAP_DESCRIPTORS  11



// BuildResourceDescriptorHob_V2 is a copy of BuildResourceDescriptorHob from
// EmbeddedPkg\Library\PrePiHobLib\Hob.c with additional MemoryType parameter
#define EFI_HOB_TYPE_RESOURCE_DESCRIPTOR_V2 0x000D
VOID* CreateHob (UINT16 HobType, UINT16 HobLength);
VOID EFIAPI BuildResourceDescriptorHob_V2 (
  IN EFI_RESOURCE_TYPE            ResourceType,
  IN EFI_RESOURCE_ATTRIBUTE_TYPE  ResourceAttribute,
  IN EFI_PHYSICAL_ADDRESS         PhysicalStart,
  IN UINT64                       NumberOfBytes,
  IN UINT64                       MemoryType)
{
  EFI_HOB_RESOURCE_DESCRIPTOR  *Hob = CreateHob (EFI_HOB_TYPE_RESOURCE_DESCRIPTOR_V2, sizeof (EFI_HOB_RESOURCE_DESCRIPTOR) + 8);
  ASSERT (Hob != NULL);

  Hob->ResourceType      = ResourceType;
  Hob->ResourceAttribute = ResourceAttribute;
  Hob->PhysicalStart     = PhysicalStart;
  Hob->ResourceLength    = NumberOfBytes;

  // Append the Memory Type at the end of the HOB
  UINT8* Ptr = (UINT8*)Hob;
  Ptr = &Ptr[sizeof (EFI_HOB_RESOURCE_DESCRIPTOR)];
  *((UINT64 *)Ptr) = MemoryType;
}




BOOLEAN
ReportDramHighSpace (
  IN OUT UINT64  *DramHighSize
  )
{
  MEM_INIT_OUTPUT_BUFFER  *MemInfoAddr = NULL;
  UINT32                  SmemSize;

  *DramHighSize = 0;
  MemInfoAddr   = SmemGetAddr (SMEM_INFO_MEM, &SmemSize);

  if (MemInfoAddr->Signature == MEM_OUTPUT_BUFFER_SIG) {
    if (MemInfoAddr->AvailableSize > 0x7800) {
      *DramHighSize = (UINT64)(((UINT64)(MemInfoAddr->AvailableSize-0x7800))<<20);
      return TRUE;
    } else {
      return FALSE;
    }
  }

  return FALSE;
}

/**
  Return the Virtual Memory Map of your platform

  This Virtual Memory Map is used by MemoryInitPei Module to initialize the MMU
  on your platform.

  @param[out]   VirtualMemoryMap    Array of ARM_MEMORY_REGION_DESCRIPTOR
                                    describing a Physical-to-Virtual Memory
                                    mapping. This array must be ended by a
                                    zero-filled entry

**/
VOID
ArmPlatformGetVirtualMemoryMap (
  IN ARM_MEMORY_REGION_DESCRIPTOR  **VirtualMemoryMap
  )
{
  UINTN    Index        = 0;
  UINT64   DramHighSize = 0;
  BOOLEAN  DramHigh     = FALSE;

  ARM_MEMORY_REGION_DESCRIPTOR  *VirtualMemoryTable;
  EFI_RESOURCE_ATTRIBUTE_TYPE   ResourceAttributes;

  ResourceAttributes = (
                        EFI_RESOURCE_ATTRIBUTE_PRESENT |
                        EFI_RESOURCE_ATTRIBUTE_INITIALIZED |
                        EFI_RESOURCE_ATTRIBUTE_WRITE_COMBINEABLE |
                        EFI_RESOURCE_ATTRIBUTE_WRITE_THROUGH_CACHEABLE |
                        EFI_RESOURCE_ATTRIBUTE_WRITE_BACK_CACHEABLE |
                        EFI_RESOURCE_ATTRIBUTE_TESTED
                        );

  DramHigh = ReportDramHighSpace (&DramHighSize);

  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_MEMORY_MAPPED_IO,
    ResourceAttributes | EFI_RESOURCE_ATTRIBUTE_UNCACHEABLE,
    0x00810000,                 // 0x00810000 is the address immediately after SPI MMIO which is declared in NorFlashStmmRuntimeDxe.c
    0x80000000 - 0x00810000,
    EFI_MEMORY_UC);


  // Reserved secure memory
  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_SYSTEM_MEMORY,
    ResourceAttributes,
    PcdGet32 (PcdReservedSecureMemoryBase),
    PcdGet32 (PcdReservedSecureMemorySize),
    EFI_MEMORY_WC
    );

  // Reserved share memory
  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_SYSTEM_MEMORY,
    ResourceAttributes,
    PcdGet32 (PcdReservedShareMemoryBase),
    PcdGet32 (PcdReservedShareMemorySize),
    EFI_MEMORY_WC
    );

  // Create the System Memory HOB for the firmware
  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_SYSTEM_MEMORY,
    ResourceAttributes,
    PcdGet64 (PcdFdBaseAddress),
    PcdGet32 (PcdFdSize),
    EFI_MEMORY_WB
    );

  // Reserved framebuffer memory
  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_MEMORY_RESERVED,
    ResourceAttributes,
    PcdGet64 (PcdArmLcdDdrFrameBufferBase),
    PcdGet32 (PcdArmLcdDdrFrameBufferSize),
    EFI_MEMORY_WC
    );

  // Create initial Base Hob for system memory.
  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_SYSTEM_MEMORY,
    ResourceAttributes,
    FixedPcdGet64 (PcdArmLcdDdrFrameBufferBase) + FixedPcdGet32 (PcdArmLcdDdrFrameBufferSize),
    mSystemMemoryEnd + 1 - (FixedPcdGet64 (PcdArmLcdDdrFrameBufferBase) + FixedPcdGet32 (PcdArmLcdDdrFrameBufferSize)),
    EFI_MEMORY_WB
    );


  if (DramHigh) {
    BuildResourceDescriptorHob_V2 (
      EFI_RESOURCE_SYSTEM_MEMORY,
      ResourceAttributes,
      FixedPcdGet64 (PcdDramHighSpaceBase),
      DramHighSize,
      EFI_MEMORY_WB
      );
  }

  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_MEMORY_MAPPED_IO,
    ResourceAttributes | EFI_RESOURCE_ATTRIBUTE_UNCACHEABLE,
    0x0000000480000000,
    0x000000FB80000000,
    EFI_MEMORY_UC);



  VirtualMemoryTable = (ARM_MEMORY_REGION_DESCRIPTOR *)AllocatePages (
                                                         EFI_SIZE_TO_PAGES (
                                                           sizeof (ARM_MEMORY_REGION_DESCRIPTOR) *
                                                           MAX_VIRTUAL_MEMORY_MAP_DESCRIPTORS
                                                           )
                                                         );
  if (VirtualMemoryTable == NULL) {
    return;
  }

  // device
  VirtualMemoryTable[Index].PhysicalBase = 0;
  VirtualMemoryTable[Index].VirtualBase  = VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index].Length       = 0x80000000;
  VirtualMemoryTable[Index++].Attributes = ARM_MEMORY_REGION_ATTRIBUTE_DEVICE;

  // reserved 0x80000000 ~ 0x824fffff secure memory
  VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet32 (PcdReservedSecureMemoryBase);
  VirtualMemoryTable[Index].VirtualBase  = FixedPcdGet32 (PcdReservedSecureMemoryBase);
  VirtualMemoryTable[Index].Length       = FixedPcdGet32 (PcdReservedSecureMemorySize);
  VirtualMemoryTable[Index++].Attributes = ARM_MEMORY_REGION_ATTRIBUTE_UNCACHED_UNBUFFERED;

  // reserved 0x82500000 ~ 0x843fffff shared non secure memory
  VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet32 (PcdReservedShareMemoryBase);
  VirtualMemoryTable[Index].VirtualBase  = FixedPcdGet32 (PcdReservedShareMemoryBase);
  VirtualMemoryTable[Index].Length       = FixedPcdGet32 (PcdReservedShareMemorySize);
  VirtualMemoryTable[Index++].Attributes = ARM_MEMORY_REGION_ATTRIBUTE_UNCACHED_UNBUFFERED;

  // system ram 0x84400000
  VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet64 (PcdFdBaseAddress);
  VirtualMemoryTable[Index].VirtualBase  = VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index].Length       = FixedPcdGet32 (PcdFdSize);
  VirtualMemoryTable[Index++].Attributes = ARM_MEMORY_REGION_ATTRIBUTE_WRITE_BACK;

  // Framebuffer Memory 0x84800000
  VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet64 (PcdArmLcdDdrFrameBufferBase);
  VirtualMemoryTable[Index].VirtualBase  = FixedPcdGet64 (PcdArmLcdDdrFrameBufferBase);
  VirtualMemoryTable[Index].Length       = FixedPcdGet32 (PcdArmLcdDdrFrameBufferSize);
  VirtualMemoryTable[Index++].Attributes = ARM_MEMORY_REGION_ATTRIBUTE_UNCACHED_UNBUFFERED;

  // system ram 0x85000000 ~
  VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet64 (PcdArmLcdDdrFrameBufferBase) + FixedPcdGet32 (PcdArmLcdDdrFrameBufferSize);
  VirtualMemoryTable[Index].VirtualBase  = VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index].Length       = mSystemMemoryEnd + 1 - VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index++].Attributes = ARM_MEMORY_REGION_ATTRIBUTE_WRITE_BACK;

  // system Dram high space 0x80_0000_0000
  if (DramHigh) {
    VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet64 (PcdDramHighSpaceBase);
    VirtualMemoryTable[Index].VirtualBase  = VirtualMemoryTable[Index].PhysicalBase;
    VirtualMemoryTable[Index].Length       = DramHighSize;
    VirtualMemoryTable[Index++].Attributes = ARM_MEMORY_REGION_ATTRIBUTE_WRITE_BACK;
  }

  // End of Table
  VirtualMemoryTable[Index].PhysicalBase = 0;
  VirtualMemoryTable[Index].VirtualBase  = 0;
  VirtualMemoryTable[Index].Length       = 0;
  VirtualMemoryTable[Index++].Attributes = (ARM_MEMORY_REGION_ATTRIBUTES)0;

  ASSERT (Index <= MAX_VIRTUAL_MEMORY_MAP_DESCRIPTORS);

  *VirtualMemoryMap = VirtualMemoryTable;
}
