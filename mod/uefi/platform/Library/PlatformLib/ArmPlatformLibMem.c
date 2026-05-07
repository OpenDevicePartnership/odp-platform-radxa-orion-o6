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

//// PATINA
//
// This entire file was re-written to support the ArmPlatformGetVirtualMemoryMap function
// which was updated to produce version 2 of the resource descriptor HOBs that cover the
// entire memory layout of the platform.
//


// The total number of descriptors, including the final "end-of-table" descriptor.
#define MAX_VIRTUAL_MEMORY_MAP_DESCRIPTORS  11

// BuildResourceDescriptorHob_V2 is a copy of BuildResourceDescriptorHob from
// EmbeddedPkg\Library\PrePiHobLib\Hob.c with additional MemoryType parameter
#define EFI_HOB_TYPE_RESOURCE_DESCRIPTOR_V2 0x000D
VOID* CreateHob (UINT16 HobType, UINT16 HobLength);
typedef struct {
  EFI_HOB_GENERIC_HEADER         Header;
  EFI_GUID                       Owner;
  EFI_RESOURCE_TYPE              ResourceType;
  EFI_RESOURCE_ATTRIBUTE_TYPE    ResourceAttribute;
  EFI_PHYSICAL_ADDRESS           PhysicalStart;
  UINT64                         ResourceLength;
  UINT64                         MemoryType;
} EFI_HOB_RESOURCE_DESCRIPTOR_V2;

VOID EFIAPI BuildResourceDescriptorHob_V2 (
  IN EFI_RESOURCE_TYPE            ResourceType,
  IN EFI_RESOURCE_ATTRIBUTE_TYPE  ResourceAttribute,
  IN EFI_PHYSICAL_ADDRESS         PhysicalStart,
  IN UINT64                       NumberOfBytes,
  IN UINT64                       MemoryType)
{
  EFI_HOB_RESOURCE_DESCRIPTOR_V2  *Hob = CreateHob (EFI_HOB_TYPE_RESOURCE_DESCRIPTOR_V2, sizeof (EFI_HOB_RESOURCE_DESCRIPTOR_V2));
  ASSERT (Hob != NULL);

  Hob->ResourceType      = ResourceType;
  Hob->ResourceAttribute = ResourceAttribute;
  Hob->PhysicalStart     = PhysicalStart;
  Hob->ResourceLength    = NumberOfBytes;
  Hob->MemoryType        = MemoryType;
}

// Original function provided by the CIX reference code to report if high DRAM space was used
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

// Standard library call to return the platform virtual memory map
VOID
ArmPlatformGetVirtualMemoryMap (
  IN ARM_MEMORY_REGION_DESCRIPTOR  **VirtualMemoryMap
  )
{
  UINTN    Index        = 0;
  UINT64   DramHighSize = 0;
  UINTN    PageCount    = EFI_SIZE_TO_PAGES (sizeof (ARM_MEMORY_REGION_DESCRIPTOR) * MAX_VIRTUAL_MEMORY_MAP_DESCRIPTORS);

  ARM_MEMORY_REGION_DESCRIPTOR *VirtualMemoryTable = (ARM_MEMORY_REGION_DESCRIPTOR *)AllocatePages (PageCount);
  if (VirtualMemoryTable == NULL) {
    ASSERT(FALSE);
    return;
  }

  // Macro to indicate a present, initialized and tested memory resource
  #define EFI_RESOURCE_ATTRIBUTE_PIT (EFI_RESOURCE_ATTRIBUTE_PRESENT | EFI_RESOURCE_ATTRIBUTE_INITIALIZED | EFI_RESOURCE_ATTRIBUTE_TESTED)

  //
  // Device MMIO Region before start of RAM - uncacheable device
  //
  VirtualMemoryTable[Index].PhysicalBase = 0x00001000; // Skip the first 4KB to avoid NULL pointer dereference issues
  VirtualMemoryTable[Index].VirtualBase  = VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index].Length       = FixedPcdGet64 (PcdSystemMemoryBase) - 0x00001000;
  VirtualMemoryTable[Index].Attributes   = ARM_MEMORY_REGION_ATTRIBUTE_DEVICE;

  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_MEMORY_MAPPED_IO,
    EFI_RESOURCE_ATTRIBUTE_PIT | EFI_RESOURCE_ATTRIBUTE_UNCACHEABLE,
    VirtualMemoryTable[Index].PhysicalBase,
    VirtualMemoryTable[Index].Length,
    EFI_MEMORY_UC);

  Index++;

  //
  // Reserved Secure Memory - write combineable (uncached RAM)
  //
  VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet32 (PcdReservedSecureMemoryBase);
  VirtualMemoryTable[Index].VirtualBase  = VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index].Length       = FixedPcdGet32 (PcdReservedSecureMemorySize);
  VirtualMemoryTable[Index].Attributes   = ARM_MEMORY_REGION_ATTRIBUTE_UNCACHED_UNBUFFERED;

  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_SYSTEM_MEMORY,
    EFI_RESOURCE_ATTRIBUTE_PIT | EFI_RESOURCE_ATTRIBUTE_WRITE_COMBINEABLE,
    VirtualMemoryTable[Index].PhysicalBase,
    VirtualMemoryTable[Index].Length,
    EFI_MEMORY_WC);

  Index++;

  //
  // Reserved Shared Non-Secure Memory - write combineable (uncached RAM)
  //
  VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet32 (PcdReservedShareMemoryBase);
  VirtualMemoryTable[Index].VirtualBase  = VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index].Length       = FixedPcdGet32 (PcdReservedShareMemorySize);
  VirtualMemoryTable[Index].Attributes   = ARM_MEMORY_REGION_ATTRIBUTE_UNCACHED_UNBUFFERED;

  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_SYSTEM_MEMORY,
    EFI_RESOURCE_ATTRIBUTE_PIT | EFI_RESOURCE_ATTRIBUTE_WRITE_COMBINEABLE,
    VirtualMemoryTable[Index].PhysicalBase,
    VirtualMemoryTable[Index].Length,
    EFI_MEMORY_WC);

  Index++;

  //
  // UEFI SPINOR Image in RAM - write back cacheable with option to set write combineable
  //
  VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet64 (PcdFdBaseAddress);
  VirtualMemoryTable[Index].VirtualBase  = VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index].Length       = FixedPcdGet32 (PcdFdSize);
  VirtualMemoryTable[Index].Attributes   = ARM_MEMORY_REGION_ATTRIBUTE_WRITE_BACK;

  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_SYSTEM_MEMORY,
    EFI_RESOURCE_ATTRIBUTE_PIT | EFI_RESOURCE_ATTRIBUTE_WRITE_COMBINEABLE | EFI_RESOURCE_ATTRIBUTE_WRITE_BACK_CACHEABLE,
    VirtualMemoryTable[Index].PhysicalBase,
    VirtualMemoryTable[Index].Length,
    EFI_MEMORY_WB);

  Index++;

  //
  // Framebuffer Memory - write combineable (uncached RAM)
  //
  VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet64 (PcdArmLcdDdrFrameBufferBase);
  VirtualMemoryTable[Index].VirtualBase  = VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index].Length       = FixedPcdGet32 (PcdArmLcdDdrFrameBufferSize);
  VirtualMemoryTable[Index].Attributes   = ARM_MEMORY_REGION_ATTRIBUTE_UNCACHED_UNBUFFERED;

  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_MEMORY_RESERVED,
    EFI_RESOURCE_ATTRIBUTE_PIT | EFI_RESOURCE_ATTRIBUTE_WRITE_COMBINEABLE,
    VirtualMemoryTable[Index].PhysicalBase,
    VirtualMemoryTable[Index].Length,
    EFI_MEMORY_WC);

  Index++;

  // Useable System RAM - write back cacheable with option to set write combineable
  VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet64 (PcdArmLcdDdrFrameBufferBase) + FixedPcdGet32 (PcdArmLcdDdrFrameBufferSize);
  VirtualMemoryTable[Index].VirtualBase  = VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index].Length       = FixedPcdGet64 (PcdSystemMemoryBase) + FixedPcdGet64 (PcdSystemMemorySize) - VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index].Attributes   = ARM_MEMORY_REGION_ATTRIBUTE_WRITE_BACK;

  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_SYSTEM_MEMORY,
    EFI_RESOURCE_ATTRIBUTE_PIT | EFI_RESOURCE_ATTRIBUTE_WRITE_COMBINEABLE | EFI_RESOURCE_ATTRIBUTE_WRITE_BACK_CACHEABLE,
    VirtualMemoryTable[Index].PhysicalBase,
    VirtualMemoryTable[Index].Length,
    EFI_MEMORY_WB);

  Index++;

  // Upper MMIO Region - uncacheable device
  VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet64 (PcdSystemMemoryBase) + FixedPcdGet64 (PcdSystemMemorySize);
  VirtualMemoryTable[Index].VirtualBase  = VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index].Length       = FixedPcdGet64 (PcdDramHighSpaceBase) - VirtualMemoryTable[Index].PhysicalBase;
  VirtualMemoryTable[Index].Attributes   = ARM_MEMORY_REGION_ATTRIBUTE_DEVICE;

  BuildResourceDescriptorHob_V2 (
    EFI_RESOURCE_MEMORY_MAPPED_IO,
    EFI_RESOURCE_ATTRIBUTE_PIT | EFI_RESOURCE_ATTRIBUTE_INITIALIZED | EFI_RESOURCE_ATTRIBUTE_UNCACHEABLE,
    VirtualMemoryTable[Index].PhysicalBase,
    VirtualMemoryTable[Index].Length,
    EFI_MEMORY_UC);

  Index++;

  // System DRAM High Space - write back cacheable with option to set write combineable
  if (ReportDramHighSpace (&DramHighSize)) {
    VirtualMemoryTable[Index].PhysicalBase = FixedPcdGet64 (PcdDramHighSpaceBase);
    VirtualMemoryTable[Index].VirtualBase  = VirtualMemoryTable[Index].PhysicalBase;
    VirtualMemoryTable[Index].Length       = DramHighSize;
    VirtualMemoryTable[Index].Attributes = ARM_MEMORY_REGION_ATTRIBUTE_WRITE_BACK;

    BuildResourceDescriptorHob_V2 (
      EFI_RESOURCE_SYSTEM_MEMORY,
      EFI_RESOURCE_ATTRIBUTE_PIT | EFI_RESOURCE_ATTRIBUTE_WRITE_COMBINEABLE | EFI_RESOURCE_ATTRIBUTE_WRITE_BACK_CACHEABLE,
      VirtualMemoryTable[Index].PhysicalBase,
      VirtualMemoryTable[Index].Length,
      EFI_MEMORY_WB);
      
    Index++;
  }

  // End of Table Marker
  VirtualMemoryTable[Index].PhysicalBase = 0;
  VirtualMemoryTable[Index].VirtualBase  = 0;
  VirtualMemoryTable[Index].Length       = 0;
  VirtualMemoryTable[Index].Attributes = (ARM_MEMORY_REGION_ATTRIBUTES)0;
  Index++;

  ASSERT (Index <= MAX_VIRTUAL_MEMORY_MAP_DESCRIPTORS);
  *VirtualMemoryMap = VirtualMemoryTable;
}
