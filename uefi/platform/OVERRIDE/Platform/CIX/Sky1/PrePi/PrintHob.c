/** @file
  Copyright (c) 2021, Intel Corporation. All rights reserved.<BR>
  SPDX-License-Identifier: BSD-2-Clause-Patent
**/

#include <PiPei.h>
#include <Library/DebugLib.h>
#include <Library/HobLib.h>
#include <Library/PrintLib.h>
#include <Library/BaseMemoryLib.h>

///
/// Strings for memory types defined by EFI_MEMORY_TYPE
///
CHAR8  *Memory_Type_Str[] = {
  "EfiReservedMemoryType",
  "EfiLoaderCode",
  "EfiLoaderData",
  "EfiBootServicesCode",
  "EfiBootServicesData",
  "EfiRuntimeServicesCode",
  "EfiRuntimeServicesData",
  "EfiConventionalMemory",
  "EfiUnusableMemory",
  "EfiACPIReclaimMemory",
  "EfiACPIMemoryNVS",
  "EfiMemoryMappedIO",
  "EfiMemoryMappedIOPortSpace",
  "EfiPalCode",
  "EfiPersistentMemory",
  "< unknown >"
};
CHAR8* MemoryTypeStr(UINTN Type)
{
  if (Type >= ARRAY_SIZE(Memory_Type_Str))
    Type = ARRAY_SIZE(Memory_Type_Str) - 1;
  return Memory_Type_Str[Type];
}

///
/// Strings for resource types defined by EFI_RESOURCE_TYPE
///
CHAR8* Resource_Type_List[] = {
  "EFI_RESOURCE_SYSTEM_MEMORY        ",
  "EFI_RESOURCE_MEMORY_MAPPED_IO     ",
  "EFI_RESOURCE_IO                   ",
  "EFI_RESOURCE_FIRMWARE_DEVICE      ",
  "EFI_RESOURCE_MEMORY_MAPPED_IO_PORT",
  "EFI_RESOURCE_MEMORY_RESERVED      ",
  "EFI_RESOURCE_IO_RESERVED          ",
  "EFI_RESOURCE_MAX_MEMORY_TYPE      ",
  "< unknown >                       "
};
CHAR8* ResourceTypeStr(UINTN Type)
{
  if (Type >= ARRAY_SIZE(Resource_Type_List))
    Type = ARRAY_SIZE(Resource_Type_List) - 1;
  return Resource_Type_List[Type];
}

///
/// Strings for HOB types defined by EFI_HOB_TYPE
///
#define EFI_HOB_TYPE_RESOURCE_DESCRIPTOR_v2 0x000D
CHAR8* Hob_Type_Str[] = {
  "EFI_HOB_TYPE_UNUSED(0)",
  "EFI_HOB_TYPE_HANDOFF",
  "EFI_HOB_TYPE_MEMORY_ALLOCATION",
  "EFI_HOB_TYPE_RESOURCE_DESCRIPTOR",
  "EFI_HOB_TYPE_GUID_EXTENSION",
  "EFI_HOB_TYPE_FV",
  "EFI_HOB_TYPE_CPU",
  "EFI_HOB_TYPE_MEMORY_POOL",
  "EFI_HOB_TYPE_UNUSED(8)",
  "EFI_HOB_TYPE_FV2",
  "EFI_HOB_TYPE_LOAD_PEIM_UNUSED",
  "EFI_HOB_TYPE_UEFI_CAPSULE",
  "EFI_HOB_TYPE_FV3",
  "EFI_HOB_TYPE_RESOURCE_DESCRIPTOR_v2",
  "< unknown >"
};
CHAR8* HobTypeStr(UINTN Type)
{
  if (Type >= ARRAY_SIZE(Hob_Type_Str))
    Type = ARRAY_SIZE(Hob_Type_Str) - 1;
  return Hob_Type_Str[Type];
}

#define EFI_MEMORY_UC             0x0000000000000001ULL
#define EFI_MEMORY_WC             0x0000000000000002ULL
#define EFI_MEMORY_WT             0x0000000000000004ULL
#define EFI_MEMORY_WB             0x0000000000000008ULL
#define EFI_MEMORY_UCE            0x0000000000000010ULL
#define EFI_MEMORY_WP             0x0000000000001000ULL
#define EFI_MEMORY_RP             0x0000000000002000ULL
#define EFI_MEMORY_XP             0x0000000000004000ULL
#define EFI_MEMORY_RO             0x0000000000020000ULL
#define EFI_MEMORY_NV             0x0000000000008000ULL
#define EFI_MEMORY_MORE_RELIABLE  0x0000000000010000ULL
#define EFI_MEMORY_SP             0x0000000000040000ULL
#define EFI_MEMORY_CPU_CRYPTO     0x0000000000080000ULL
#define EFI_MEMORY_RUNTIME        0x8000000000000000ULL
#define EFI_MEMORY_ISA_VALID      0x4000000000000000ULL
#define EFI_MEMORY_ISA_MASK       0x0FFFF00000000000ULL

CHAR8 AttrStr[128];
CHAR8* MemoryAttributesStr(UINT64 Attributes)
{
  AttrStr[0] = 0;
  if ((Attributes & EFI_MEMORY_UC) == EFI_MEMORY_UC)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_UC ");
  if ((Attributes & EFI_MEMORY_WC) == EFI_MEMORY_WC)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_WC ");
  if ((Attributes & EFI_MEMORY_WT) == EFI_MEMORY_WT)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_WT ");
  if ((Attributes & EFI_MEMORY_WB) == EFI_MEMORY_WB)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_WB ");
  if ((Attributes & EFI_MEMORY_UCE) == EFI_MEMORY_UCE)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_UCE ");
  if ((Attributes & EFI_MEMORY_WP) == EFI_MEMORY_WP)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_WP ");
  if ((Attributes & EFI_MEMORY_RP) == EFI_MEMORY_RP)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_RP ");
  if ((Attributes & EFI_MEMORY_XP) == EFI_MEMORY_XP)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_XP ");
  if ((Attributes & EFI_MEMORY_RO) == EFI_MEMORY_RO)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_RO ");
  if ((Attributes & EFI_MEMORY_NV) == EFI_MEMORY_NV)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_NV ");
  if ((Attributes & EFI_MEMORY_MORE_RELIABLE) == EFI_MEMORY_MORE_RELIABLE)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_MORE_RELIABLE ");
  if ((Attributes & EFI_MEMORY_SP) == EFI_MEMORY_SP)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_SP ");
  if ((Attributes & EFI_MEMORY_CPU_CRYPTO) == EFI_MEMORY_CPU_CRYPTO)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_CPU_CRYPTO ");
  if ((Attributes & EFI_MEMORY_RUNTIME) == EFI_MEMORY_RUNTIME)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_RUNTIME ");
  if ((Attributes & EFI_MEMORY_ISA_VALID) == EFI_MEMORY_ISA_VALID)  AsciiStrCatS (AttrStr, 128, "EFI_MEMORY_ISA_VALID ");

  return AttrStr;
}


VOID
PrintHex (
  IN  UINT8   *DataStart,
  IN  UINT16  DataSize
  )
{
  for (UINTN i = 0; i < DataSize; i++)
  {
    if ((i % 16) == 0){
      DEBUG ((DEBUG_INFO, "  "));
    }
    DEBUG ((DEBUG_INFO, " %02x", DataStart[i]));
    if ((i % 16) == 15) {
      DEBUG ((DEBUG_INFO, "\n"));
    }
  }
  if ((DataSize % 16) != 0) {  
    DEBUG ((DEBUG_INFO, "\n"));
  }
}


VOID
PrintHob (EFI_PEI_HOB_POINTERS  Hob)
{
  DEBUG ((DEBUG_INFO, "%a\n", HobTypeStr(Hob.Header->HobType)));
  DEBUG ((DEBUG_INFO, "   HDR.Type = %d\n", Hob.Header->HobType));
  DEBUG ((DEBUG_INFO, "   HDR.Length = 0x%04x\n", Hob.Header->HobLength));

  switch(Hob.Header->HobType) {
    case EFI_HOB_TYPE_HANDOFF:
      ASSERT (Hob.Header->HobLength >= sizeof (*Hob.HandoffInformationTable));
      DEBUG ((DEBUG_INFO, "   BootMode            = 0x%08x\n", Hob.HandoffInformationTable->BootMode));
      DEBUG ((DEBUG_INFO, "   EfiMemoryTop        = 0x%016lx\n", Hob.HandoffInformationTable->EfiMemoryTop));
      DEBUG ((DEBUG_INFO, "   EfiMemoryBottom     = 0x%016lx\n", Hob.HandoffInformationTable->EfiMemoryBottom));
      DEBUG ((DEBUG_INFO, "   EfiFreeMemoryTop    = 0x%016lx\n", Hob.HandoffInformationTable->EfiFreeMemoryTop));
      DEBUG ((DEBUG_INFO, "   EfiFreeMemoryBottom = 0x%016lx\n", Hob.HandoffInformationTable->EfiFreeMemoryBottom));
      DEBUG ((DEBUG_INFO, "   EfiEndOfHobList     = 0x%016lx\n", Hob.HandoffInformationTable->EfiEndOfHobList));
      break;

    case EFI_HOB_TYPE_MEMORY_ALLOCATION:
      ASSERT (Hob.Header->HobLength >= sizeof (*Hob.MemoryAllocation));
      DEBUG ((DEBUG_INFO, "   Name              = %g\n", &(Hob.MemoryAllocation->AllocDescriptor.Name)));
      DEBUG ((DEBUG_INFO, "   MemoryBaseAddress = 0x%016lx\n", Hob.MemoryAllocation->AllocDescriptor.MemoryBaseAddress));
      DEBUG ((DEBUG_INFO, "   MemoryLength      = 0x%016lx\n", Hob.MemoryAllocation->AllocDescriptor.MemoryLength));
      DEBUG ((DEBUG_INFO, "   MemoryType        = %a\n", MemoryTypeStr(Hob.MemoryAllocation->AllocDescriptor.MemoryType)));
      break;

    case EFI_HOB_TYPE_RESOURCE_DESCRIPTOR:
      ASSERT (Hob.Header->HobLength >= sizeof (*Hob.ResourceDescriptor));
      DEBUG ((DEBUG_INFO, "   ResourceType      = %a\n", ResourceTypeStr(Hob.ResourceDescriptor->ResourceType)));
      DEBUG ((DEBUG_INFO, "   Owner             = %g\n", &(Hob.ResourceDescriptor->Owner)));
      DEBUG ((DEBUG_INFO, "   ResourceAttribute = 0x%04x\n", Hob.ResourceDescriptor->ResourceAttribute));
      DEBUG ((DEBUG_INFO, "   PhysicalStart     = 0x%016lx\n", Hob.ResourceDescriptor->PhysicalStart));
      DEBUG ((DEBUG_INFO, "   ResourceLength    = 0x%016lx\n", Hob.ResourceDescriptor->ResourceLength));
      break;

    case EFI_HOB_TYPE_RESOURCE_DESCRIPTOR_v2:
      ASSERT (Hob.Header->HobLength >= (sizeof (*Hob.ResourceDescriptor) + sizeof(UINT64)));
      DEBUG ((DEBUG_INFO, "   ResourceType      = %a\n", ResourceTypeStr(Hob.ResourceDescriptor->ResourceType)));
      DEBUG ((DEBUG_INFO, "   Owner             = %g\n", &(Hob.ResourceDescriptor->Owner)));
      DEBUG ((DEBUG_INFO, "   ResourceAttribute = 0x%04x\n", Hob.ResourceDescriptor->ResourceAttribute));
      DEBUG ((DEBUG_INFO, "   PhysicalStart     = 0x%016lx\n", Hob.ResourceDescriptor->PhysicalStart));
      DEBUG ((DEBUG_INFO, "   ResourceLength    = 0x%016lx\n", Hob.ResourceDescriptor->ResourceLength));
      UINT64* Attributes = (UINT64*)((UINT8*)Hob.ResourceDescriptor + sizeof(EFI_HOB_RESOURCE_DESCRIPTOR));
      DEBUG ((DEBUG_INFO, "   Attributes        = %a\n", MemoryAttributesStr(*Attributes)));
      break;

    case EFI_HOB_TYPE_GUID_EXTENSION:
      ASSERT (Hob.Header->HobLength >= sizeof (*Hob.Guid));
      DEBUG ((DEBUG_INFO, "   Name = %g\n", &(Hob.Guid->Name)));
      break;

    case EFI_HOB_TYPE_FV:
      ASSERT (Hob.Header->HobLength >= sizeof (*Hob.FirmwareVolume));
      DEBUG ((DEBUG_INFO, "   BaseAddress = 0x%016lx\n", Hob.FirmwareVolume->BaseAddress));
      DEBUG ((DEBUG_INFO, "   Length      = 0x%016lx\n", Hob.FirmwareVolume->Length));
      break;

    case EFI_HOB_TYPE_FV2:
      ASSERT (Hob.Header->HobLength >= sizeof (*Hob.FirmwareVolume2));
      DEBUG ((DEBUG_INFO, "   BaseAddress = 0x%016lx\n", Hob.FirmwareVolume2->BaseAddress));
      DEBUG ((DEBUG_INFO, "   Length      = 0x%016lx\n", Hob.FirmwareVolume2->Length));
      DEBUG ((DEBUG_INFO, "   FvName      = %g\n", &(Hob.FirmwareVolume2->FvName)));
      DEBUG ((DEBUG_INFO, "   FileName    = %g\n", &(Hob.FirmwareVolume2->FileName)));
      break;

    case EFI_HOB_TYPE_CPU:
      ASSERT (Hob.Header->HobLength >= sizeof (*Hob.Cpu));
      DEBUG ((DEBUG_INFO, "   SizeOfMemorySpace = 0x%016lx\n", Hob.Cpu->SizeOfMemorySpace));
      DEBUG ((DEBUG_INFO, "   SizeOfIoSpace     = 0x%016lx\n", Hob.Cpu->SizeOfIoSpace));
      break;

    case EFI_HOB_TYPE_MEMORY_POOL:
      break;
  }

  PrintHex (Hob.Raw, Hob.Header->HobLength);
}

VOID
PrintAllHobs ( )
{
  EFI_PEI_HOB_POINTERS  Hob;
  UINTN Count = 0;

  Hob.Raw = GetFirstHob (EFI_HOB_TYPE_HANDOFF);
  while (!END_OF_HOB_LIST (Hob))
  {
    DEBUG ((DEBUG_INFO, "HOB[%d] ", Count++));
    PrintHob(Hob);
    Hob.Raw = GET_NEXT_HOB (Hob);
  }

  DEBUG ((DEBUG_INFO, "EFI_HOB_TYPE_MEMORY_ALLOCATION Table\n"));
  DEBUG ((DEBUG_INFO, "   MemoryBaseAddress    MemoryLength         MemoryType\n"));
  Hob.Raw = GetFirstHob (EFI_HOB_TYPE_HANDOFF);
  while (!END_OF_HOB_LIST (Hob))
  {
    if (Hob.Header->HobType == EFI_HOB_TYPE_MEMORY_ALLOCATION)
    {
      ASSERT (Hob.Header->HobLength >= sizeof (*Hob.MemoryAllocation));
      DEBUG ((DEBUG_INFO, "   0x%016lx   0x%016lx   %a\n",
        Hob.MemoryAllocation->AllocDescriptor.MemoryBaseAddress,
        Hob.MemoryAllocation->AllocDescriptor.MemoryLength,
        MemoryTypeStr(Hob.MemoryAllocation->AllocDescriptor.MemoryType)
        ));
    }
    Hob.Raw = GET_NEXT_HOB (Hob);
  }

  DEBUG ((DEBUG_INFO, "EFI_HOB_TYPE_RESOURCE_DESCRIPTOR Table\n"));
  DEBUG ((DEBUG_INFO, "   ResourceType                         Attr     PhysicalStart        ResourceLength       AllocateResource\n"));
  Hob.Raw = GetFirstHob (EFI_HOB_TYPE_HANDOFF);
  while (!END_OF_HOB_LIST (Hob))
  {
    if (Hob.Header->HobType == EFI_HOB_TYPE_RESOURCE_DESCRIPTOR || Hob.Header->HobType == EFI_HOB_TYPE_RESOURCE_DESCRIPTOR_v2)
    {
      ASSERT (Hob.Header->HobLength >= sizeof (*Hob.ResourceDescriptor));
      DEBUG ((DEBUG_INFO, "   %a   0x%04x   0x%016lx   0x%016lx",
        ResourceTypeStr(Hob.ResourceDescriptor->ResourceType),
        Hob.ResourceDescriptor->ResourceAttribute,
        Hob.ResourceDescriptor->PhysicalStart,
        Hob.ResourceDescriptor->ResourceLength
        ));
      if (Hob.Header->HobType == EFI_HOB_TYPE_RESOURCE_DESCRIPTOR_v2) {
        UINT64* Attributes = (UINT64*)((UINT8*)Hob.ResourceDescriptor + sizeof(EFI_HOB_RESOURCE_DESCRIPTOR));
        DEBUG((DEBUG_INFO, "   %a\n", MemoryAttributesStr(*Attributes)));
      } else {
        DEBUG((DEBUG_INFO, "   N/A\n"));
      }
    }
    Hob.Raw = GET_NEXT_HOB (Hob);
  }
}
