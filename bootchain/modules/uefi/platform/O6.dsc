# @file
#
#  Copyright 2024-2025 Radxa Computer (Shenzhen) Co., Ltd. All Rights Reserved.
#  Copyright 2022 Cix Technology (Shanghai) Co., Ltd. All Rights Reserved.
#  Copyright (c) 2011 - 2020, ARM Limited. All rights reserved.
#  Copyright (c) 2017 - 2018, Andrei Warkentin <andrey.warkentin@gmail.com>
#  Copyright (c) 2015 - 2021, Intel Corporation. All rights reserved.
#  Copyright (c) 2014, Linaro Limited. All rights reserved.
#
#  SPDX-License-Identifier: BSD-2-Clause-Patent
#
##

[Defines]
  PLATFORM_NAME                  = O6
  PLATFORM_GUID                  = 53cfca21-0399-4802-a3c0-e86437a42183
  PLATFORM_VERSION               = 1.0
  DSC_SPECIFICATION              = 0x0001001A
  OUTPUT_DIRECTORY               = $(PATH_BUILD_OUTPUT)
  SUPPORTED_ARCHITECTURES        = AARCH64
  BUILD_TARGETS                  = DEBUG|RELEASE|NOOPT
  SKUID_IDENTIFIER               = DEFAULT
  FLASH_DEFINITION               = platform/O6.fdf
  PCD_DYNAMIC_AS_DYNAMICEX       = TRUE
  BUILD_NUMBER                   = 0x00000004

[LibraryClasses]
  CacheMaintenanceLib|ArmPkg/Library/ArmCacheMaintenanceLib/ArmCacheMaintenanceLib.inf
  ArmGenericTimerCounterLib|ArmPkg/Library/ArmGenericTimerPhyCounterLib/ArmGenericTimerPhyCounterLib.inf
  ArmLib|ArmPkg/Library/ArmLib/ArmBaseLib.inf
  ArmMmuLib|ArmPkg/Library/ArmMmuLib/ArmMmuBaseLib.inf
  EfiResetSystemLib|ArmPkg/Library/ArmPsciResetSystemLib/ArmPsciResetSystemLib.inf
  ArmSmcLib|ArmPkg/Library/ArmSmcLib/ArmSmcLib.inf
  NULL|ArmPkg/Library/CompilerIntrinsicsLib/CompilerIntrinsicsLib.inf
  PeCoffExtraActionLib|ArmPkg/Library/DebugPeCoffExtraActionLib/DebugPeCoffExtraActionLib.inf

  ArmPlatformStackLib|ArmPlatformPkg/Library/ArmPlatformStackLib/ArmPlatformStackLib.inf
  PL011UartLib|ArmPlatformPkg/Library/PL011UartLib/PL011UartLib.inf

  BaseCryptLib|CryptoPkg/Library/BaseCryptLib/BaseCryptLib.inf
  IntrinsicLib|CryptoPkg/Library/IntrinsicLib/IntrinsicLib.inf
  OpensslLib|CryptoPkg/Library/OpensslLib/OpensslLib.inf

  AcpiHelperLib|DynamicTablesPkg/Library/Common/AcpiHelperLib/AcpiHelperLib.inf
  TableHelperLib|DynamicTablesPkg/Library/Common/TableHelperLib/TableHelperLib.inf

  AcpiLib|EmbeddedPkg/Library/AcpiLib/AcpiLib.inf
  FdtLib|EmbeddedPkg/Library/FdtLib/FdtLib.inf
  DmaLib|EmbeddedPkg/Library/NonCoherentDmaLib/NonCoherentDmaLib.inf
  TimeBaseLib|EmbeddedPkg/Library/TimeBaseLib/TimeBaseLib.inf

  BmpSupportLib|MdeModulePkg/Library/BaseBmpSupportLib/BaseBmpSupportLib.inf
  BootLogoLib|MdeModulePkg/Library/BootLogoLib/BootLogoLib.inf
  CustomizedDisplayLib|MdeModulePkg/Library/CustomizedDisplayLib/CustomizedDisplayLib.inf
  DebugAgentLib|MdeModulePkg/Library/DebugAgentLibNull/DebugAgentLibNull.inf
  CapsuleLib|MdeModulePkg/Library/DxeCapsuleLibNull/DxeCapsuleLibNull.inf
  PerformanceLib|MdeModulePkg/Library/DxePerformanceLib/DxePerformanceLib.inf
  ReportStatusCodeLib|MdeModulePkg/Library/DxeReportStatusCodeLib/DxeReportStatusCodeLib.inf
  SecurityManagementLib|MdeModulePkg/Library/DxeSecurityManagementLib/DxeSecurityManagementLib.inf
  FileExplorerLib|MdeModulePkg/Library/FileExplorerLib/FileExplorerLib.inf
  NonDiscoverableDeviceRegistrationLib|MdeModulePkg/Library/NonDiscoverableDeviceRegistrationLib/NonDiscoverableDeviceRegistrationLib.inf
  UefiBootManagerLib|MdeModulePkg/Library/UefiBootManagerLib/UefiBootManagerLib.inf
  HiiLib|MdeModulePkg/Library/UefiHiiLib/UefiHiiLib.inf
  UefiHiiServicesLib|MdeModulePkg/Library/UefiHiiServicesLib/UefiHiiServicesLib.inf
  SortLib|MdeModulePkg/Library/UefiSortLib/UefiSortLib.inf
  VariablePolicyHelperLib|MdeModulePkg/Library/VariablePolicyHelperLib/VariablePolicyHelperLib.inf

  DebugPrintErrorLevelLib|MdePkg/Library/BaseDebugPrintErrorLevelLib/BaseDebugPrintErrorLevelLib.inf
  IoLib|MdePkg/Library/BaseIoLibIntrinsic/BaseIoLibIntrinsic.inf
  BaseLib|MdePkg/Library/BaseLib/BaseLib.inf
  BaseMemoryLib|MdePkg/Library/BaseMemoryLib/BaseMemoryLib.inf
  OrderedCollectionLib|MdePkg/Library/BaseOrderedCollectionRedBlackTreeLib/BaseOrderedCollectionRedBlackTreeLib.inf
  PeCoffGetEntryPointLib|MdePkg/Library/BasePeCoffGetEntryPointLib/BasePeCoffGetEntryPointLib.inf
  PeCoffLib|MdePkg/Library/BasePeCoffLib/BasePeCoffLib.inf
  PrintLib|MdePkg/Library/BasePrintLib/BasePrintLib.inf
  SafeIntLib|MdePkg/Library/BaseSafeIntLib/BaseSafeIntLib.inf
  NULL|MdePkg/Library/BaseStackCheckLib/BaseStackCheckLib.inf
  SynchronizationLib|MdePkg/Library/BaseSynchronizationLib/BaseSynchronizationLib.inf
  UefiDecompressLib|MdePkg/Library/BaseUefiDecompressLib/BaseUefiDecompressLib.inf
  HobLib|MdePkg/Library/DxeHobLib/DxeHobLib.inf
  PcdLib|MdePkg/Library/DxePcdLib/DxePcdLib.inf
  DxeServicesLib|MdePkg/Library/DxeServicesLib/DxeServicesLib.inf
  DxeServicesTableLib|MdePkg/Library/DxeServicesTableLib/DxeServicesTableLib.inf
  RegisterFilterLib|MdePkg/Library/RegisterFilterLibNull/RegisterFilterLibNull.inf
  UefiApplicationEntryPoint|MdePkg/Library/UefiApplicationEntryPoint/UefiApplicationEntryPoint.inf
  UefiBootServicesTableLib|MdePkg/Library/UefiBootServicesTableLib/UefiBootServicesTableLib.inf
  DevicePathLib|MdePkg/Library/UefiDevicePathLib/UefiDevicePathLib.inf
  UefiDriverEntryPoint|MdePkg/Library/UefiDriverEntryPoint/UefiDriverEntryPoint.inf
  FileHandleLib|MdePkg/Library/UefiFileHandleLib/UefiFileHandleLib.inf
  UefiLib|MdePkg/Library/UefiLib/UefiLib.inf
  MemoryAllocationLib|MdePkg/Library/UefiMemoryAllocationLib/UefiMemoryAllocationLib.inf
  UefiRuntimeLib|MdePkg/Library/UefiRuntimeLib/UefiRuntimeLib.inf
  UefiRuntimeServicesTableLib|MdePkg/Library/UefiRuntimeServicesTableLib/UefiRuntimeServicesTableLib.inf
  UefiUsbLib|MdePkg/Library/UefiUsbLib/UefiUsbLib.inf

  NetLib|NetworkPkg/Library/DxeNetLib/DxeNetLib.inf

  PlatformSecureLib|OvmfPkg/Library/PlatformSecureLib/PlatformSecureLib.inf

  AmlLib|Platform/CIX/Sky1/Library/Acpi/CIX/AmlLib/AmlLib.inf
  DebugLib|Platform/CIX/Sky1/Library/BaseDebugLibSerialPort/BaseDebugLibSerialPort.inf
  BaseHidParseReportLib|Platform/CIX/Sky1/Library/BaseHidParseReportLib/BaseHidParseReportLib.inf
  CixFwBootPerfLib|Platform/CIX/Sky1/Library/CixFwBootPerfLib/CixFwBootPerfLib.inf
  CixGPNVLib|Platform/CIX/Sky1/Library/CixGPNVLib/CixGPNVLib.inf
  CixS3IoLib|Platform/CIX/Sky1/Library/CixS3IoLib/CixS3IoLib.inf
  DTpmDeviceLib|Platform/CIX/Sky1/Library/DTpmDeviceLib/DTpmDeviceLib.inf
  DtbCommonLib|Platform/CIX/Sky1/Library/DtbCommonLib/DtbCommonLib.inf
  DtbUpdateLibSi|Platform/CIX/Sky1/Library/DtbUpdateLibSi/DtbUpdateLib.inf
  Tcg2PhysicalPresenceLib|Platform/CIX/Sky1/Library/DxeTcg2PhysicalPresenceLib/DxeTcg2PhysicalPresenceLib.inf
  EdkiiSystemCapsuleLib|Platform/CIX/Sky1/Library/EdkiiSystemCapsuleLib/EdkiiSystemCapsuleLib.inf
  FTpmDeviceLib|Platform/CIX/Sky1/Library/FTpmDeviceLibNull/FTpmDeviceLibNull.inf
  FlashUpdateLib|Platform/CIX/Sky1/Library/FlashUpdateLib/FlashUpdateLib.inf
  EcLib|Platform/CIX/Sky1/Library/Ite5570EcLib/Ite5570EcLib.inf
  OpteeLib|Platform/CIX/Sky1/Library/OpteeLib/OpteeLib.inf
  PartitionLib|Platform/CIX/Sky1/Library/PartitionLib/PartitionLib.inf
  PlatformBootManagerLib|Platform/CIX/Sky1/Library/PlatformBootManagerLib/PlatformBootManagerLib.inf
  PlatformConfigParamsDataBlockLib|Platform/CIX/Sky1/Library/PlatformConfigParamsDataBlockLib/PlatformConfigParamsDataBlockLib.inf
  OemMiscLib|Platform/CIX/Sky1/Library/SmbiosMiscLib/SmbiosMiscLib.inf
  StmmInfoLib|Platform/CIX/Sky1/Library/StmmInfoLib/StmmInfoLib.inf
  Tpm2DeviceLib|Platform/CIX/Sky1/Library/Tpm2DeviceLib/Tpm2DeviceLib.inf
  PlatformBootHookLib|Platform/CIX/Sky1/Merak/Library/PlatformBootHookLib/PlatformBootHookLib.inf
  ArmPlatformLib|platform/Library/PlatformLib/PlatformLib.inf
  RealTimeClockLib|Platform/Radxa/Library/Hym8563RealTimeClockLib/Hym8563RealTimeClockLib.inf
  PdEcLib|Platform/Radxa/Library/PdEcLibNull/PdEcLibNull.inf
  PlatformConfigParamsHookLib|Platform/Radxa/Orion/O6/Library/PlatformConfigParamsHookLib/PlatformConfigParamsHookLib.inf
  PlatformEnvHookLib|Platform/Radxa/Orion/O6/Library/PlatformEnvHookLib/PlatformEnvHookLib.inf

  TpmMeasurementLib|SecurityPkg/Library/DxeTpmMeasurementLib/DxeTpmMeasurementLib.inf
  FmpAuthenticationLib|SecurityPkg/Library/FmpAuthenticationLibPkcs7/FmpAuthenticationLibPkcs7.inf
  PlatformPKProtectionLib|SecurityPkg/Library/PlatformPKProtectionLibVarPolicy/PlatformPKProtectionLibVarPolicy.inf
  SecureBootVariableLib|SecurityPkg/Library/SecureBootVariableLib/SecureBootVariableLib.inf
  SecureBootVariableProvisionLib|SecurityPkg/Library/SecureBootVariableProvisionLib/SecureBootVariableProvisionLib.inf
  Tcg2PpVendorLib|SecurityPkg/Library/Tcg2PpVendorLibNull/Tcg2PpVendorLibNull.inf
  Tpm2CommandLib|SecurityPkg/Library/Tpm2CommandLib/Tpm2CommandLib.inf

  TimerLib|Silicon/CIX/Sky1/Library/ArmArchTimerLib/ArmArchTimerLib.inf
  PostCodeLib|Silicon/CIX/Sky1/Library/CixBasePostCodeLibMmio/BasePostCodeLibMmio.inf
  ArmMtlLib|Silicon/CIX/Sky1/Library/CixMtlLib/CixMtlLib.inf
  CixSipLib|Silicon/CIX/Sky1/Library/CixSipLib/CixSipLib.inf
  ConfigParamsDataBlockLib|Silicon/CIX/Sky1/Library/ConfigParamsDataBlockLib/ConfigParamsDataBlockLib.inf
  ConfigParamsHookLib|Silicon/CIX/Sky1/Library/ConfigParamsHookNullLib/ConfigParamsHookNullLib.inf
  CpuInfoLib|Silicon/CIX/Sky1/Library/CpuInfoLib/CpuInfoLib.inf
  CsuPmIpcLib|Silicon/CIX/Sky1/Library/CsuPmIpcLib/CsuPmIpcLib.inf
  DisplayLib|Silicon/CIX/Sky1/Library/DisplayLib/DisplayLib.inf
  FchDmaLib|Silicon/CIX/Sky1/Library/FchDmaLib/FchDmaLib.inf
  FchTimerLib|Silicon/CIX/Sky1/Library/FchTimerLib/FchTimerLib.inf
  FirmwareParseLib|Silicon/CIX/Sky1/Library/FirmwareParseLib/FirmwareParseLib.inf
  GpioLib|Silicon/CIX/Sky1/Library/GpioLib/GpioLib.inf
  GpioTableLib|Silicon/CIX/Sky1/Library/GpioTableNullLib/GpioTableNullLib.inf
  HwHarvestLib|Silicon/CIX/Sky1/Library/HwHarvestLib/HwHarvestLib.inf
  HwMutexLib|Silicon/CIX/Sky1/Library/HwMutexLib/HwMutexLib.inf
  I2cLib|Silicon/CIX/Sky1/Library/I2cLib/I2cLib.inf
  MailBoxLib|Silicon/CIX/Sky1/Library/MailBoxLib/MailBoxLib.inf
  NorFlashLib|Silicon/CIX/Sky1/Library/NorFlashLib/NorFlashStmmRuntimeLib.inf
  OpnLib|Silicon/CIX/Sky1/Library/OpnLib/OpnLib.inf
  SerialPortLib|Silicon/CIX/Sky1/Library/PL011SerialPortLib/PL011SerialPortLib.inf
  PL011UartClockLib|Silicon/CIX/Sky1/Library/PL011UartClockLib/PL011UartClockLib.inf
  PciHostBridgeLib|Silicon/CIX/Sky1/Library/PciHostBridgeLib/PciHostBridgeLib.inf
  PciSegmentLib|Silicon/CIX/Sky1/Library/PciSegmentLib/PciSegmentLib.inf
  PinMuxLib|Silicon/CIX/Sky1/Library/PinMuxLib/PinMuxLib.inf
  PinMuxTableLib|Silicon/CIX/Sky1/Library/PinMuxTableNullLib/PinMuxTableNullLib.inf
  PlatformPcieLib|Silicon/CIX/Sky1/Library/PlatformPcieLib/PlatformPcieLib.inf
  RebootReasonLib|Silicon/CIX/Sky1/Library/RebootReasonLib/RebootReasonLib.inf
  RngLib|Silicon/CIX/Sky1/Library/RngLib/RngLib.inf
  ShMemLib|Silicon/CIX/Sky1/Library/ShMemLib/ShMemLib.inf
  SocInitLib|Silicon/CIX/Sky1/Library/SocInitLib/SocInitLib.inf
  SpiLib|Silicon/CIX/Sky1/Library/SpiLib/SpiLib.inf
  TrngLib|Silicon/CIX/Sky1/Library/TrngLib/TrngLib.inf
  UsbLib|Silicon/CIX/Sky1/Library/UsbLib/UsbLib.inf

[LibraryClasses.common.DXE_RUNTIME_DRIVER]
  CapsuleLib|MdeModulePkg/Library/DxeCapsuleLibFmp/DxeRuntimeCapsuleLib.inf
  DebugLib|MdePkg/Library/DxeRuntimeDebugLibSerialPort/DxeRuntimeDebugLibSerialPort.inf
  EcLib|Platform/CIX/Sky1/Library/Ite5570EcLib/Ite5570EcRuntimeLib.inf
  EfiResetSystemLib|Platform/Radxa/Library/ArmPsciResetSystemLib/ArmPsciResetSystemLib.inf
  GpioLib|Silicon/CIX/Sky1/Library/GpioLib/GpioRuntimeLib.inf
  HwMutexLib|Silicon/CIX/Sky1/Library/HwMutexLib/HwMutexRuntimeLib.inf
  PinMuxLib|Silicon/CIX/Sky1/Library/PinMuxLib/PinMuxRuntimeLib.inf

[PcdsFeatureFlag]
  gEfiMdeModulePkgTokenSpaceGuid.PcdTurnOffUsbLegacySupport|TRUE
  gEfiMdeModulePkgTokenSpaceGuid.PcdInstallAcpiSdtProtocol|TRUE
  gEfiMdeModulePkgTokenSpaceGuid.PcdEnableVariableRuntimeCache|FALSE
  gEfiMdeModulePkgTokenSpaceGuid.PcdVariableCollectStatistics|TRUE
  gEmbeddedTokenSpaceGuid.PcdPrePiProduceMemoryTypeInformationHob|TRUE

[PcdsDynamicExDefault.common.DEFAULT]
  gEfiMdeModulePkgTokenSpaceGuid.PcdSystemFmpCapsuleImageTypeIdGuid|{0x08, 0x98, 0x1c, 0x35, 0x53, 0x4b, 0x63, 0x43, 0x93, 0x14, 0xd3, 0x39, 0x38, 0x6e, 0x56, 0x85}
  gEfiSignedCapsulePkgTokenSpaceGuid.PcdEdkiiSystemFirmwareImageDescriptor|{0x0}|VOID*|0x100
  gEfiSignedCapsulePkgTokenSpaceGuid.PcdEdkiiSystemFirmwareFileGuid|{0xcf, 0x4f, 0x2e, 0x64, 0xf7, 0x2d, 0x15, 0x44, 0x8b, 0x70, 0xa0, 0x39, 0x09, 0xc5, 0x7b, 0x55}

[PcdsFixedAtBuild]
  gArmPlatformTokenSpaceGuid.PcdArmLcdDdrFrameBufferBase|0x84800000
  gArmPlatformTokenSpaceGuid.PcdArmLcdDdrFrameBufferSize|0x00800000
  gArmPlatformTokenSpaceGuid.PcdCoreCount|12
  gArmPlatformTokenSpaceGuid.PcdCPUCorePrimaryStackSize|0x40000
  gArmPlatformTokenSpaceGuid.PcdSerialDbgInterrupt|330
  gArmPlatformTokenSpaceGuid.PcdSerialDbgRegisterBase|0x040D0000
  gArmPlatformTokenSpaceGuid.PcdSerialDbgUartBaudRate|115200
  gArmPlatformTokenSpaceGuid.PcdWatchdogCount|1
  gArmPlatformTokenSpaceGuid.PL011UartClkInHz|100000000 #100Mhz 100000000 #25Mhz 25000000
  gArmPlatformTokenSpaceGuid.PL011UartInterrupt|330
  gArmTokenSpaceGuid.PcdArmArchTimerFreqInHz|1000000000 #1Ghz 1000000000 #1Mhz 1000000
  gArmTokenSpaceGuid.PcdArmPrimaryCore|0x400  #core4
  gArmTokenSpaceGuid.PcdGenericWatchdogControlBase|0x16003000
  gArmTokenSpaceGuid.PcdGenericWatchdogEl2IntrNum|408
  gArmTokenSpaceGuid.PcdGenericWatchdogRefreshBase|0x16008000
  gArmTokenSpaceGuid.PcdGicDistributorBase|0x0e010000    #0x0e001000
  gArmTokenSpaceGuid.PcdGicRedistributorsBase|0x0e090000 #0x0e081000
  gArmTokenSpaceGuid.PcdProcessorAssetTag|L" "
  gArmTokenSpaceGuid.PcdProcessorManufacturer|L"Cix Technology Group Co., Ltd."
  gArmTokenSpaceGuid.PcdProcessorPartNumber|L" "
  gArmTokenSpaceGuid.PcdSystemMemoryBase|0x80000000
  gArmTokenSpaceGuid.PcdSystemMemorySize|0x400000000
  gArmTokenSpaceGuid.PcdSystemProductName|L"Radxa Orion O6"
  gCixPlatformTokenSpaceGuid.PcdAcpiGpio0IoMask|0x20000000 # vbus for usb port6-7
  gCixPlatformTokenSpaceGuid.PcdAcpiGpio3IoMask|0x00018000 # pwm/edp en pin output
  gCixPlatformTokenSpaceGuid.PcdAcpiPrefPmProf|0x01  # Desktop
  gCixPlatformTokenSpaceGuid.PcdAcpiSpcrEnable|TRUE
  gCixPlatformTokenSpaceGuid.PcdActiveTpmInterfaceType|0x01
  gCixPlatformTokenSpaceGuid.PcdDTPMSpiChipSelect|0x1   # 1:Slave Select 0   2:Slave Select 1
  gCixPlatformTokenSpaceGuid.PcdDTPMSupport|TRUE
  gCixPlatformTokenSpaceGuid.PcdEcAcpiI2cEn|TRUE
  gCixPlatformTokenSpaceGuid.PcdPdDevAlertPins|{ 9, 0xFF, 9, 0xFF }
  gCixPlatformTokenSpaceGuid.PcdPdDevI2cBuses|{ 0x1, 0xFF, 0x1, 0xFF }
  gCixPlatformTokenSpaceGuid.PcdPdDevI2cSlaveAddresses|{ 0x30, 0xFF, 0x31, 0xFF }
  gCixPlatformTokenSpaceGuid.PcdReservedAndroidBase|0x140000000
  gCixPlatformTokenSpaceGuid.PcdReservedAndroidSize|0x120000000
  gCixPlatformTokenSpaceGuid.PcdSiliconDtbUpdateEnable|TRUE
  gCixPlatformTokenSpaceGuid.PcdSiliconDtbUpdateFileName|L"sky1-orion-o6.dtb"
  gCixPlatformTokenSpaceGuid.PcdTypecPortDefaultModes|{ 1, 4, 1, 4}
  gCixTokenSpaceGuid.PcdAcpiCppcType|0x02
  gCixTokenSpaceGuid.PcdAcpiCpuLpiState|0x1
  gCixTokenSpaceGuid.PcdAcpiCsiDmaEnable|FALSE
  gCixTokenSpaceGuid.PcdAcpiUart0Enable|FALSE
  gCixTokenSpaceGuid.PcdCixProcessorVersion|L"CIX P1 CD8180"
  gCixTokenSpaceGuid.PcdCpuCore2En|FALSE
  gCixTokenSpaceGuid.PcdCpuCore3En|FALSE
  gCixTokenSpaceGuid.PcdCpuCore4En|FALSE
  gCixTokenSpaceGuid.PcdCpuCore5En|FALSE
  gCixTokenSpaceGuid.PcdDPPriority0|1 # highest priority
  gCixTokenSpaceGuid.PcdDPPriority1|4 #
  gCixTokenSpaceGuid.PcdDPPriority2|0 #
  gCixTokenSpaceGuid.PcdDPPriority4|2 # lowest priority
  gCixTokenSpaceGuid.PcdI2c0BusFreq|100000
  gCixTokenSpaceGuid.PcdI2c0En|TRUE
  gCixTokenSpaceGuid.PcdI2c1BusFreq|100000
  gCixTokenSpaceGuid.PcdI2c1En|TRUE
  gCixTokenSpaceGuid.PcdI2c2BusFreq|100000
  gCixTokenSpaceGuid.PcdI2c3BusFreq|100000
  gCixTokenSpaceGuid.PcdI2c3En|TRUE
  gCixTokenSpaceGuid.PcdI2c3Runtime|TRUE     # For RTC runtime service
  gCixTokenSpaceGuid.PcdI2c4BusFreq|100000
  gCixTokenSpaceGuid.PcdI2c4En|TRUE
  gCixTokenSpaceGuid.PcdI2c5BusFreq|100000
  gCixTokenSpaceGuid.PcdI2c5En|TRUE
  gCixTokenSpaceGuid.PcdI2c6BusFreq|50000
  gCixTokenSpaceGuid.PcdI2c6En|TRUE
  gCixTokenSpaceGuid.PcdI2c7BusFreq|100000
  gCixTokenSpaceGuid.PcdI2c7En|TRUE
  gCixTokenSpaceGuid.PcdI2cCtrlEn|0xF7
  gCixTokenSpaceGuid.PcdIspCamera0Power|0x00
  gCixTokenSpaceGuid.PcdIspCamera1Power|0x00
  gCixTokenSpaceGuid.PcdIspCamera2Power|0x00
  gCixTokenSpaceGuid.PcdIspCamera3Power|0x00
  gCixTokenSpaceGuid.PcdNorFlashNvramAddr|0x00380000
  gCixTokenSpaceGuid.PcdNorFlashNvramSize|0x28000
  gCixTokenSpaceGuid.PcdPcieRootPort0Enable|TRUE
  gCixTokenSpaceGuid.PcdPcieRootPort0PeResetPin|2
  gCixTokenSpaceGuid.PcdPcieRootPort1Enable|TRUE
  gCixTokenSpaceGuid.PcdPcieRootPort1PeResetPin|4
  gCixTokenSpaceGuid.PcdPcieRootPort2Enable|TRUE
  gCixTokenSpaceGuid.PcdPcieRootPort2PeResetPin|5
  gCixTokenSpaceGuid.PcdPcieRootPort3Enable|TRUE
  gCixTokenSpaceGuid.PcdPcieRootPort3PeResetPin|3
  gCixTokenSpaceGuid.PcdPcieRootPort4Enable|TRUE
  gCixTokenSpaceGuid.PcdPcieRootPort4PeResetPin|6
  gCixTokenSpaceGuid.PcdSpi0En|TRUE
  gCixTokenSpaceGuid.PcdSystemTableSelect|0x00
  gCixTokenSpaceGuid.PcdUsb2Control0Enable|TRUE
  gCixTokenSpaceGuid.PcdUsb2Control1Enable|TRUE
  gCixTokenSpaceGuid.PcdUsb2Control2Enable|TRUE
  gCixTokenSpaceGuid.PcdUsb2Control3Enable|TRUE
  gCixTokenSpaceGuid.PcdUsb3Control0Enable|TRUE
  gCixTokenSpaceGuid.PcdUsb3Control1Enable|TRUE
  gCixTokenSpaceGuid.PcdUsbCControl0Enable|TRUE
  gCixTokenSpaceGuid.PcdUsbCControl1Enable|TRUE
  gCixTokenSpaceGuid.PcdUsbCControl2Enable|TRUE
  gEfiMdeModulePkgTokenSpaceGuid.PcdBootManagerMenuFile|{ 0x21, 0xaa, 0x2c, 0x46, 0x14, 0x76, 0x03, 0x45, 0x83, 0x6e, 0x8a, 0xb6, 0xf4, 0x66, 0x23, 0x31 }
  gEfiMdeModulePkgTokenSpaceGuid.PcdDiskIoDataBufferBlockNum|1024
  gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareRevision|0x00000003
!if $(TARGET) == RELEASE
  gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVersionString|L"9.0.3"
!else
  gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVersionString|L"9.0.3-$(COMMIT_HASH)-debug:$(BUILD_DATE)"
!endif
  gEfiMdeModulePkgTokenSpaceGuid.PcdResetOnMemoryTypeInformationChange|FALSE
  gEfiMdeModulePkgTokenSpaceGuid.PcdSerialRegisterBase|0x040D0000 #0x091e1000 #0x0a051000
  gEfiMdeModulePkgTokenSpaceGuid.PcdSmbiosEntryPointProvideMethod|0x2
  gEfiMdeModulePkgTokenSpaceGuid.PcdSmbiosVersion|0x0306
  gEfiMdePkgTokenSpaceGuid.PcdDebugPrintErrorLevel|0x800000CF
  gEfiMdePkgTokenSpaceGuid.PcdDefaultTerminalType|4
  gEfiMdePkgTokenSpaceGuid.PcdPerformanceLibraryPropertyMask|1
  gEfiMdePkgTokenSpaceGuid.PcdPostCodePropertyMask|0x08
  gEfiMdePkgTokenSpaceGuid.PcdReportStatusCodePropertyMask|0x07
  gEfiMdePkgTokenSpaceGuid.PcdUartDefaultReceiveFifoDepth|0
  gEfiMdePkgTokenSpaceGuid.PcdUefiVariableDefaultPlatformLangCodes|"en-US"
  gEfiNetworkPkgTokenSpaceGuid.PcdIPv4HttpSupport|TRUE
  gEfiNetworkPkgTokenSpaceGuid.PcdIPv6HttpSupport|TRUE
  gEfiNetworkPkgTokenSpaceGuid.PcdNetworkStackSupport|FALSE
  gEmbeddedTokenSpaceGuid.PcdDefaultDtPref|FALSE
  gEmbeddedTokenSpaceGuid.PcdMemoryTypeEfiBootServicesCode|1500
  gEmbeddedTokenSpaceGuid.PcdMemoryTypeEfiBootServicesData|13000
  gEmbeddedTokenSpaceGuid.PcdMemoryTypeEfiLoaderCode|0x1000
  gEmbeddedTokenSpaceGuid.PcdMemoryTypeEfiRuntimeServicesCode|1200
  gEmbeddedTokenSpaceGuid.PcdMemoryTypeEfiRuntimeServicesData|0x450
  gEmbeddedTokenSpaceGuid.PcdPrePiCpuIoSize|44
  gFmpDevicePkgTokenSpaceGuid.PcdFmpDeviceImageTypeIdGuid|{GUID("351c9808-4b53-4363-9314-d339386e5685")}
  gHym8563RealTimeClockLibTokenSpaceGuid.PcdI2cBusFrequency|100000
  gRadxaTokenSpaceGuid.PcdEdk2CixCommitHash|L"$(COMMIT_HASH)"

[PcdsPatchableInModule]
  gEfiMdeModulePkgTokenSpaceGuid.PcdSerialClockRate|500000000
!if $(TARGET) == RELEASE
  gEfiMdePkgTokenSpaceGuid.PcdDebugPropertyMask|0x21
!else
  gEfiMdePkgTokenSpaceGuid.PcdDebugPropertyMask|0x2f
!endif

[PcdsDynamicHii.common.DEFAULT]
  gEfiMdeModulePkgTokenSpaceGuid.PcdBootDiscoveryPolicy|L"BootDiscoveryPolicy"|gBootDiscoveryPolicyMgrFormsetGuid|0
  gEfiMdePkgTokenSpaceGuid.PcdPlatformBootTimeOut|L"Timeout"|gEfiGlobalVariableGuid|0x0|5

[PcdsDynamicDefault]
  gEfiMdeModulePkgTokenSpaceGuid.PcdFlashNvStorageVariableSize|0x28000
  gEfiMdeModulePkgTokenSpaceGuid.PcdFlashNvStorageFtwWorkingSize|0x28000
  gEfiMdeModulePkgTokenSpaceGuid.PcdFlashNvStorageFtwSpareSize|0x28000
  gEfiMdeModulePkgTokenSpaceGuid.PcdFlashNvStorageVariableBase64|0x00380000
  gEfiMdeModulePkgTokenSpaceGuid.PcdFlashNvStorageFtwWorkingBase64|(0x00380000 + 0x28000)
  gEfiMdeModulePkgTokenSpaceGuid.PcdFlashNvStorageFtwSpareBase64|(0x00380000 + 0x28000 + 0x28000)
  gEfiMdeModulePkgTokenSpaceGuid.PcdVideoHorizontalResolution|1920
  gEfiMdeModulePkgTokenSpaceGuid.PcdVideoVerticalResolution|1080
  gEfiMdeModulePkgTokenSpaceGuid.PcdSetupVideoHorizontalResolution|800
  gEfiMdeModulePkgTokenSpaceGuid.PcdSetupVideoVerticalResolution|600
  gEfiSecurityPkgTokenSpaceGuid.PcdTpmInstanceGuid|{0x5a, 0xf2, 0x6b, 0x28, 0xc3, 0xc2, 0x8c, 0x40, 0xb3, 0xb4, 0x25, 0xe6, 0x75, 0x8b, 0x73, 0x17}
  gEmbeddedTokenSpaceGuid.PcdDmaDeviceLimit|0x47fffffff

[Components]
  ArmPkg/Drivers/ArmPciCpuIo2Dxe/ArmPciCpuIo2Dxe.inf
  ArmPkg/Drivers/TimerDxe/TimerDxe.inf
  ArmPkg/Universal/Smbios/ProcessorSubClassDxe/ProcessorSubClassDxe.inf

  DynamicTablesPkg/Drivers/DynamicTableFactoryDxe/DynamicTableFactoryDxe.inf {
    <LibraryClasses>
      NULL|Platform/CIX/Sky1/Library/Acpi/CIX/AcpiMadtLibCIX/AcpiMadtLibCIX.inf
      NULL|Platform/CIX/Sky1/Library/Acpi/CIX/AcpiSsdtCpuTopologyLibCIX/SsdtCpuTopologyLibCIX.inf
      NULL|Platform/CIX/Sky1/Library/Acpi/CIX/AcpiPpttLibCIX/AcpiPpttLibCIX.inf
  }

  EmbeddedPkg/Drivers/ConsolePrefDxe/ConsolePrefDxe.inf
  EmbeddedPkg/Drivers/DtPlatformDxe/DtPlatformDxe.inf {
    <LibraryClasses>
      DtPlatformDtbLoaderLib|EmbeddedPkg/Library/DxeDtPlatformDtbLoaderLibDefault/DxeDtPlatformDtbLoaderLibDefault.inf
  }
  EmbeddedPkg/Drivers/NonCoherentIoMmuDxe/NonCoherentIoMmuDxe.inf
  EmbeddedPkg/MetronomeDxe/MetronomeDxe.inf
  EmbeddedPkg/RealTimeClockRuntimeDxe/RealTimeClockRuntimeDxe.inf
  EmbeddedPkg/ResetRuntimeDxe/ResetRuntimeDxe.inf

  FatPkg/EnhancedFatDxe/Fat.inf

  FmpDevicePkg/FmpDxe/FmpDxe.inf {
    <Defines>
      FILE_GUID = 351c9808-4b53-4363-9314-d339386e5685
    <PcdsFixedAtBuild>
      gFmpDevicePkgTokenSpaceGuid.PcdFmpDeviceImageIdName|L"Radxa System Firmware Device"
      gFmpDevicePkgTokenSpaceGuid.PcdFmpDevicePkcs7CertBufferXdr|{0x00, 0x00, 0x03, 0xF0, 0x30, 0x82, 0x03, 0xEC, 0x30, 0x82, 0x02, 0xD4, 0xA0, 0x03, 0x02, 0x01, 0x02, 0x02, 0x09, 0x00, 0xC0, 0x91, 0xC5, 0xE2, 0xB7, 0x66, 0xC0, 0xF8, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B, 0x05, 0x00, 0x30, 0x81, 0x82, 0x31, 0x0B, 0x30, 0x09, 0x06, 0x03, 0x55, 0x04, 0x06, 0x13, 0x02, 0x43, 0x4E, 0x31, 0x0B, 0x30, 0x09, 0x06, 0x03, 0x55, 0x04, 0x08, 0x0C, 0x02, 0x53, 0x48, 0x31, 0x0B, 0x30, 0x09, 0x06, 0x03, 0x55, 0x04, 0x07, 0x0C, 0x02, 0x53, 0x48, 0x31, 0x12, 0x30, 0x10, 0x06, 0x03, 0x55, 0x04, 0x0A, 0x0C, 0x09, 0x54, 0x69, 0x61, 0x6E, 0x6F, 0x43, 0x6F, 0x72, 0x65, 0x31, 0x0E, 0x30, 0x0C, 0x06, 0x03, 0x55, 0x04, 0x0B, 0x0C, 0x05, 0x45, 0x44, 0x4B, 0x49, 0x49, 0x31, 0x11, 0x30, 0x0F, 0x06, 0x03, 0x55, 0x04, 0x03, 0x0C, 0x08, 0x54, 0x65, 0x73, 0x74, 0x52, 0x6F, 0x6F, 0x74, 0x31, 0x22, 0x30, 0x20, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x01, 0x16, 0x13, 0x65, 0x64, 0x6B, 0x69, 0x69, 0x40, 0x74, 0x69, 0x61, 0x6E, 0x6F, 0x63, 0x6F, 0x72, 0x65, 0x2E, 0x6F, 0x72, 0x67, 0x30, 0x1E, 0x17, 0x0D, 0x31, 0x37, 0x30, 0x34, 0x31, 0x30, 0x30, 0x38, 0x32, 0x37, 0x34, 0x30, 0x5A, 0x17, 0x0D, 0x31, 0x37, 0x30, 0x35, 0x31, 0x30, 0x30, 0x38, 0x32, 0x37, 0x34, 0x30, 0x5A, 0x30, 0x81, 0x82, 0x31, 0x0B, 0x30, 0x09, 0x06, 0x03, 0x55, 0x04, 0x06, 0x13, 0x02, 0x43, 0x4E, 0x31, 0x0B, 0x30, 0x09, 0x06, 0x03, 0x55, 0x04, 0x08, 0x0C, 0x02, 0x53, 0x48, 0x31, 0x0B, 0x30, 0x09, 0x06, 0x03, 0x55, 0x04, 0x07, 0x0C, 0x02, 0x53, 0x48, 0x31, 0x12, 0x30, 0x10, 0x06, 0x03, 0x55, 0x04, 0x0A, 0x0C, 0x09, 0x54, 0x69, 0x61, 0x6E, 0x6F, 0x43, 0x6F, 0x72, 0x65, 0x31, 0x0E, 0x30, 0x0C, 0x06, 0x03, 0x55, 0x04, 0x0B, 0x0C, 0x05, 0x45, 0x44, 0x4B, 0x49, 0x49, 0x31, 0x11, 0x30, 0x0F, 0x06, 0x03, 0x55, 0x04, 0x03, 0x0C, 0x08, 0x54, 0x65, 0x73, 0x74, 0x52, 0x6F, 0x6F, 0x74, 0x31, 0x22, 0x30, 0x20, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x01, 0x16, 0x13, 0x65, 0x64, 0x6B, 0x69, 0x69, 0x40, 0x74, 0x69, 0x61, 0x6E, 0x6F, 0x63, 0x6F, 0x72, 0x65, 0x2E, 0x6F, 0x72, 0x67, 0x30, 0x82, 0x01, 0x22, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0F, 0x00, 0x30, 0x82, 0x01, 0x0A, 0x02, 0x82, 0x01, 0x01, 0x00, 0xB9, 0x29, 0x29, 0x6C, 0x60, 0x0C, 0xD7, 0x23, 0xF6, 0x7D, 0xEE, 0xF0, 0x62, 0xFF, 0xD9, 0xC9, 0xAA, 0x55, 0x8C, 0x81, 0x95, 0x56, 0x3F, 0xB7, 0x56, 0x53, 0xB0, 0xC2, 0x82, 0x12, 0xC5, 0x3B, 0x75, 0x23, 0xB9, 0x4D, 0xD6, 0xC4, 0x55, 0x73, 0xF3, 0xAA, 0x95, 0xA8, 0x1B, 0xF3, 0x93, 0x7E, 0x9E, 0x40, 0xE4, 0x1D, 0x22, 0x9C, 0x93, 0x07, 0x0B, 0xD7, 0xAA, 0x5B, 0xD7, 0xE4, 0x1A, 0x21, 0x84, 0xD7, 0x63, 0x59, 0x03, 0x50, 0x1F, 0xF5, 0x14, 0x55, 0x93, 0x91, 0x9B, 0xF5, 0x52, 0xB0, 0xBF, 0x0E, 0x5C, 0x68, 0x3B, 0x59, 0x52, 0x98, 0x96, 0x56, 0xE1, 0xAB, 0xC4, 0x43, 0xBB, 0x05, 0x57, 0x78, 0x45, 0x01, 0x9F, 0x58, 0x15, 0x53, 0x0E, 0x11, 0x94, 0x2F, 0x0E, 0xF1, 0xA6, 0x19, 0xA2, 0x6E, 0x86, 0x39, 0x2B, 0x33, 0x8D, 0xC7, 0xC5, 0xEB, 0xEE, 0x1E, 0x33, 0xD3, 0x32, 0x94, 0xC1, 0x59, 0xC4, 0x0C, 0x97, 0x0B, 0x12, 0x48, 0x5F, 0x33, 0xF6, 0x60, 0x74, 0x7D, 0x57, 0xC2, 0x13, 0x2D, 0x7D, 0xA9, 0x87, 0xA3, 0x35, 0xEA, 0x91, 0x83, 0x3F, 0x67, 0x7A, 0x92, 0x1F, 0x01, 0x53, 0x9F, 0x62, 0x5F, 0x99, 0x12, 0xFD, 0x73, 0x1B, 0x2D, 0x9E, 0x2B, 0x6C, 0x34, 0x49, 0xAF, 0x4F, 0x07, 0x8F, 0xC0, 0xE9, 0x6B, 0x9E, 0x5F, 0x79, 0x35, 0xDA, 0x2A, 0x5C, 0x88, 0xEE, 0xF6, 0x48, 0x61, 0xDA, 0x96, 0xE3, 0x48, 0x46, 0xA0, 0x94, 0x1C, 0x9D, 0xF6, 0x5C, 0x87, 0x0E, 0xEF, 0x74, 0x09, 0x91, 0x0D, 0x3D, 0x5A, 0xE7, 0xC5, 0x4C, 0x8A, 0x7A, 0xAC, 0xA1, 0x85, 0xB6, 0x67, 0x44, 0x17, 0x55, 0x52, 0x3A, 0xE8, 0x11, 0x4D, 0x58, 0xA2, 0x93, 0x00, 0x62, 0xEA, 0x7B, 0x80, 0xED, 0xCF, 0xBD, 0xDF, 0x75, 0x80, 0x4B, 0xB9, 0x65, 0x63, 0xAD, 0x0B, 0x4D, 0x74, 0xFA, 0x59, 0x02, 0x03, 0x01, 0x00, 0x01, 0xA3, 0x63, 0x30, 0x61, 0x30, 0x1D, 0x06, 0x03, 0x55, 0x1D, 0x0E, 0x04, 0x16, 0x04, 0x14, 0x16, 0xAA, 0xD6, 0x8E, 0x1B, 0x2D, 0x43, 0xF3, 0x2D, 0xB0, 0x24, 0xAD, 0x36, 0x65, 0x3F, 0xB2, 0xFA, 0xB1, 0x2C, 0xED, 0x30, 0x1F, 0x06, 0x03, 0x55, 0x1D, 0x23, 0x04, 0x18, 0x30, 0x16, 0x80, 0x14, 0x16, 0xAA, 0xD6, 0x8E, 0x1B, 0x2D, 0x43, 0xF3, 0x2D, 0xB0, 0x24, 0xAD, 0x36, 0x65, 0x3F, 0xB2, 0xFA, 0xB1, 0x2C, 0xED, 0x30, 0x0F, 0x06, 0x03, 0x55, 0x1D, 0x13, 0x01, 0x01, 0xFF, 0x04, 0x05, 0x30, 0x03, 0x01, 0x01, 0xFF, 0x30, 0x0E, 0x06, 0x03, 0x55, 0x1D, 0x0F, 0x01, 0x01, 0xFF, 0x04, 0x04, 0x03, 0x02, 0x01, 0x86, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B, 0x05, 0x00, 0x03, 0x82, 0x01, 0x01, 0x00, 0x95, 0xDE, 0xDF, 0xA4, 0x14, 0xDB, 0x92, 0x22, 0x78, 0x1A, 0xBD, 0x31, 0x9D, 0x1E, 0xD7, 0x2F, 0x0A, 0x10, 0x11, 0x5D, 0x74, 0x61, 0xE8, 0x30, 0xC4, 0xF3, 0x15, 0xE9, 0x30, 0x54, 0xF4, 0xBB, 0x0C, 0x04, 0x78, 0x13, 0x5D, 0x2C, 0xDD, 0x8C, 0x92, 0x90, 0xD1, 0x9C, 0xD0, 0xD0, 0x18, 0xA3, 0xA3, 0xFC, 0x8C, 0x28, 0x5A, 0xD4, 0x91, 0x4D, 0x08, 0xC3, 0xF6, 0x1A, 0xC8, 0xDD, 0xA6, 0x08, 0x58, 0xE2, 0x15, 0x95, 0xFB, 0x2D, 0x2D, 0x8A, 0xB1, 0x30, 0x80, 0xBD, 0x9A, 0xB6, 0xE1, 0x2C, 0x20, 0x3E, 0xDD, 0xC4, 0xC7, 0x55, 0x65, 0xCF, 0x28, 0x17, 0xF4, 0xEE, 0xDA, 0xBE, 0x77, 0x70, 0xD5, 0x52, 0xD6, 0x15, 0x7A, 0xFB, 0xAD, 0xAF, 0xFD, 0xD5, 0x45, 0x90, 0x5A, 0xE6, 0x31, 0x42, 0xD7, 0x84, 0xB3, 0x49, 0x56, 0x6A, 0xD3, 0x47, 0xF3, 0xBF, 0x68, 0x60, 0x8B, 0x0F, 0xE2, 0xAF, 0xF4, 0xE3, 0xEC, 0x12, 0xB9, 0xE2, 0x3A, 0x16, 0x11, 0x4E, 0x4D, 0x73, 0x79, 0xAF, 0x47, 0x85, 0x4C, 0x76, 0x26, 0x9E, 0x8B, 0x32, 0xC0, 0x8E, 0xC2, 0xDC, 0x27, 0xA6, 0xEF, 0xAC, 0x93, 0x9E, 0xA1, 0x5E, 0xCF, 0x34, 0x45, 0xE0, 0x2A, 0xC7, 0x9D, 0x4D, 0xD7, 0xD7, 0x37, 0x72, 0x97, 0xF8, 0x58, 0xF9, 0xB6, 0x35, 0x48, 0xF1, 0xD1, 0x0A, 0x72, 0x7F, 0xFD, 0x4D, 0x7C, 0xE9, 0xCC, 0xD8, 0x48, 0x1B, 0x49, 0x52, 0x53, 0xDE, 0x51, 0x01, 0x53, 0x35, 0xBC, 0x90, 0xCD, 0x8C, 0x8A, 0xCC, 0x43, 0x20, 0xA7, 0x45, 0xFF, 0x2B, 0x55, 0xB0, 0x8B, 0x2D, 0xFF, 0x55, 0x15, 0x4B, 0x84, 0xD0, 0xC3, 0xD3, 0x90, 0x9C, 0x94, 0x4B, 0x55, 0xD5, 0x62, 0xEA, 0x22, 0xAB, 0x62, 0x68, 0xDD, 0x53, 0xC6, 0xDC, 0xA5, 0xDD, 0x9A, 0x2D, 0x8E, 0x79, 0x7C, 0x2E, 0x9C, 0xE4, 0x66, 0x80, 0x8C, 0x1D}
    <LibraryClasses>
      FmpPayloadHeaderLib|FmpDevicePkg/Library/FmpPayloadHeaderLibV1/FmpPayloadHeaderLibV1.inf
      FmpDependencyLib|FmpDevicePkg/Library/FmpDependencyLib/FmpDependencyLib.inf
      FmpDependencyCheckLib|FmpDevicePkg/Library/FmpDependencyCheckLibNull/FmpDependencyCheckLibNull.inf
      FmpDependencyDeviceLib|FmpDevicePkg/Library/FmpDependencyDeviceLibNull/FmpDependencyDeviceLibNull.inf
      CapsuleUpdatePolicyLib|FmpDevicePkg/Library/CapsuleUpdatePolicyLibNull/CapsuleUpdatePolicyLibNull.inf
      FmpDeviceLib|FmpDevicePkg/Library/FmpDeviceLibNull/FmpDeviceLibNull.inf
  }

  MdeModulePkg/Application/UiApp/UiApp.inf {
    <LibraryClasses>
      NULL|MdeModulePkg/Library/BootDiscoveryPolicyUiLib/BootDiscoveryPolicyUiLib.inf
      NULL|MdeModulePkg/Library/DeviceManagerUiLib/DeviceManagerUiLib.inf
      NULL|MdeModulePkg/Library/BootManagerUiLib/BootManagerUiLib.inf
      NULL|MdeModulePkg/Library/BootMaintenanceManagerUiLib/BootMaintenanceManagerUiLib.inf
  }
  MdeModulePkg/Application/VariableInfo/VariableInfo.inf
  MdeModulePkg/Bus/Ata/AtaAtapiPassThru/AtaAtapiPassThru.inf
  MdeModulePkg/Bus/Ata/AtaBusDxe/AtaBusDxe.inf
  MdeModulePkg/Bus/Pci/EhciDxe/EhciDxe.inf
  MdeModulePkg/Bus/Pci/NonDiscoverablePciDeviceDxe/NonDiscoverablePciDeviceDxe.inf
  MdeModulePkg/Bus/Pci/PciHostBridgeDxe/PciHostBridgeDxe.inf
  MdeModulePkg/Bus/Pci/SataControllerDxe/SataControllerDxe.inf
  MdeModulePkg/Bus/Pci/UhciDxe/UhciDxe.inf
  MdeModulePkg/Bus/Pci/XhciDxe/XhciDxe.inf
  MdeModulePkg/Bus/Usb/UsbBusDxe/UsbBusDxe.inf
  MdeModulePkg/Bus/Usb/UsbKbDxe/UsbKbDxe.inf
  MdeModulePkg/Bus/Usb/UsbMassStorageDxe/UsbMassStorageDxe.inf
  MdeModulePkg/Bus/Usb/UsbMouseDxe/UsbMouseDxe.inf
  MdeModulePkg/Core/RuntimeDxe/RuntimeDxe.inf
  MdeModulePkg/Universal/Acpi/AcpiTableDxe/AcpiTableDxe.inf
  MdeModulePkg/Universal/Acpi/FirmwarePerformanceDataTableDxe/FirmwarePerformanceDxe.inf {
    <LibraryClasses>
      LockBoxLib|MdeModulePkg/Library/LockBoxNullLib/LockBoxNullLib.inf
  }
  MdeModulePkg/Universal/BdsDxe/BdsDxe.inf
  MdeModulePkg/Universal/BootManagerPolicyDxe/BootManagerPolicyDxe.inf
  MdeModulePkg/Universal/CapsuleRuntimeDxe/CapsuleRuntimeDxe.inf
  MdeModulePkg/Universal/Console/ConPlatformDxe/ConPlatformDxe.inf
  MdeModulePkg/Universal/Console/ConSplitterDxe/ConSplitterDxe.inf
  MdeModulePkg/Universal/Console/GraphicsConsoleDxe/GraphicsConsoleDxe.inf
  MdeModulePkg/Universal/Console/TerminalDxe/TerminalDxe.inf
  MdeModulePkg/Universal/DevicePathDxe/DevicePathDxe.inf
  MdeModulePkg/Universal/Disk/DiskIoDxe/DiskIoDxe.inf
  MdeModulePkg/Universal/Disk/PartitionDxe/PartitionDxe.inf
  MdeModulePkg/Universal/Disk/RamDiskDxe/RamDiskDxe.inf
  MdeModulePkg/Universal/Disk/UnicodeCollation/EnglishDxe/EnglishDxe.inf
  MdeModulePkg/Universal/DisplayEngineDxe/DisplayEngineDxe.inf
  MdeModulePkg/Universal/EbcDxe/EbcDxe.inf
  MdeModulePkg/Universal/EsrtDxe/EsrtDxe.inf
  MdeModulePkg/Universal/EsrtFmpDxe/EsrtFmpDxe.inf
  MdeModulePkg/Universal/HiiDatabaseDxe/HiiDatabaseDxe.inf
  MdeModulePkg/Universal/MonotonicCounterRuntimeDxe/MonotonicCounterRuntimeDxe.inf
  MdeModulePkg/Universal/PCD/Dxe/Pcd.inf {
    <LibraryClasses>
      PcdLib|MdePkg/Library/BasePcdLibNull/BasePcdLibNull.inf
  }
  MdeModulePkg/Universal/ReportStatusCodeRouter/RuntimeDxe/ReportStatusCodeRouterRuntimeDxe.inf
  MdeModulePkg/Universal/SecurityStubDxe/SecurityStubDxe.inf {
    <LibraryClasses>
      NULL|SecurityPkg/Library/DxeImageVerificationLib/DxeImageVerificationLib.inf
  }
  MdeModulePkg/Universal/SerialDxe/SerialDxe.inf
  MdeModulePkg/Universal/SerialDxe/SerialDxe.inf
  MdeModulePkg/Universal/SetupBrowserDxe/SetupBrowserDxe.inf
  MdeModulePkg/Universal/SmbiosDxe/SmbiosDxe.inf
  MdeModulePkg/Universal/Variable/RuntimeDxe/VariableSmmRuntimeDxe.inf {
    <LibraryClasses>
      MmUnblockMemoryLib|MdePkg/Library/MmUnblockMemoryLib/MmUnblockMemoryLibNull.inf
  }

  Platform/CIX/Sky1/Application/Fastboot/Fastboot.inf
  Platform/CIX/Sky1/Drivers/AcpiSocDxe/AcpiSocDxe.inf
  Platform/CIX/Sky1/Drivers/AcpiSocTables/AcpiSocTables.inf
  Platform/CIX/Sky1/Drivers/ArmScmiDxe/ArmScmiDxe.inf
  Platform/CIX/Sky1/Drivers/CapsuleUpdateDxe/CapsuleUpdateDxe.inf
  Platform/CIX/Sky1/Drivers/CixSmbiosDxe/CixSmbiosDxe.inf
  Platform/CIX/Sky1/Drivers/ConfigurationManagerDxe/ConfigurationManagerDxe.inf
  Platform/CIX/Sky1/Drivers/DtbUpdateDxeSi/DtbUpdateDxe.inf
  Platform/CIX/Sky1/Drivers/DynamicTableManagerDxe/DynamicTableManagerDxe.inf
  Platform/CIX/Sky1/Drivers/EcPlatformDxe/EcPlatformDxe.inf
  Platform/CIX/Sky1/Drivers/FirmwareUpdateDxe/FwUpdateProtocolDxe.inf
  Platform/CIX/Sky1/Drivers/FwVersionDxe/FwVersionDxe.inf
  Platform/CIX/Sky1/Drivers/FwVersionDxe/FwVersionProtocolTest.inf
  Platform/CIX/Sky1/Drivers/I2cHidDeviceDxe/I2cHidDeviceDxe.inf
  Platform/CIX/Sky1/Drivers/I2cHidKeyboard/I2cHidKeyboard.inf
  Platform/CIX/Sky1/Drivers/I2cHidServiceDriver/I2cHidServiceDriver.inf
  Platform/CIX/Sky1/Drivers/LaunchFastbootDxe/LaunchFastbootDxe.inf
  Platform/CIX/Sky1/Drivers/MmCommunicationDxe/ArmMmCommunication.inf {
    <LibraryClasses>
      NULL|StandaloneMmPkg/Library/VariableMmDependency/VariableMmDependency.inf
  }
  Platform/CIX/Sky1/Drivers/NvmExpressDxe/NvmExpressDxe.inf
  Platform/CIX/Sky1/Drivers/Pci/PciBusDxe/PciBusDxe.inf
  Platform/CIX/Sky1/Drivers/PdDxe/PdDxe.inf {
    <LibraryClasses>
      PdLib|Platform/CIX/Sky1/Library/Rts5453hPdLib/Rts5453hPdLib.inf
      RedriverLib|Platform/CIX/Sky1/Library/PI3DPX1207RedriverLib/PI3DPX1207RedriverLib.inf
  }
  Platform/CIX/Sky1/Drivers/PlatformConfigParamsManageDxe/PlatformConfigParamsManageDxe.inf
  Platform/CIX/Sky1/Drivers/PlatformDxe/PlatformDxe.inf
  Platform/CIX/Sky1/Drivers/PlatformSetupVariableInitDxe/PlatformSetupVariableInitDxe.inf
  Platform/CIX/Sky1/Drivers/PowerButtonDxe/PowerButtonDxe.inf
  Platform/CIX/Sky1/Drivers/S3SaveStateDxe/S3SaveStateDxe.inf
  Platform/CIX/Sky1/Drivers/SecureBootDxe/SecureBootDxe.inf
  Platform/CIX/Sky1/Drivers/SystemFirmwareUpdate/SystemFirmwareReportDxe.inf
  Platform/CIX/Sky1/Drivers/TPMVariableDxe/TPMVariableDxe.inf
  Platform/CIX/Sky1/Drivers/Tcg2Acpi/Tcg2Acpi.inf
  Platform/CIX/Sky1/Drivers/Tcg2Config/Tcg2ConfigDxe.inf
  Platform/CIX/Sky1/Drivers/UsbDeviceControlDxe/UsbDeviceControlDxe.inf
  Platform/CIX/Sky1/PrePi/PeiUniCore.inf {
    <LibraryClasses>
      PcdLib|MdePkg/Library/BasePcdLibNull/BasePcdLibNull.inf
      MemoryInitPeiLib|Platform/CIX/Sky1/Library/MemoryInitPeiLib/MemoryInitPeiLib.inf
      PlatformPeiLib|ArmPlatformPkg/PlatformPei/PlatformPeiLib.inf
      ExtractGuidedSectionLib|EmbeddedPkg/Library/PrePiExtractGuidedSectionLib/PrePiExtractGuidedSectionLib.inf
      LzmaDecompressLib|MdeModulePkg/Library/LzmaCustomDecompressLib/LzmaCustomDecompressLib.inf
      PrePiLib|EmbeddedPkg/Library/PrePiLib/PrePiLib.inf
      HobLib|EmbeddedPkg/Library/PrePiHobLib/PrePiHobLib.inf
      PrePiHobListPointerLib|ArmPlatformPkg/Library/PrePiHobListPointerLib/PrePiHobListPointerLib.inf
      MemoryAllocationLib|EmbeddedPkg/Library/PrePiMemoryAllocationLib/PrePiMemoryAllocationLib.inf
      PerformanceLib|MdePkg/Library/BasePerformanceLibNull/BasePerformanceLibNull.inf
  }
  
  platform/OVERRIDE/Silicon/CIX/Sky1/Drivers/LcdGraphicsOutputDxe/LcdGraphicsOutputDxe.inf
  platform/OVERRIDE/Silicon/CIX/Sky1/Drivers/NorFlashStmmRuntimeDxe/NorFlashStmmRuntimeDxe.inf

  Platform/Radxa/Drivers/AcpiPlatformDxe/AcpiPlatformDxe.inf
  Platform/Radxa/Drivers/Logo/LogoDxe.inf
  Platform/Radxa/Orion/O6/DeviceTree/DeviceTree.inf
  Platform/Radxa/Orion/O6/Drivers/AcpiPlatfomTables/AcpiPlatfomTables.inf
  Platform/Radxa/Orion/O6/Drivers/PlatformSmbios/PlatformSmbios.inf
  Platform/Radxa/Platforms/CIX/Sky1/Drivers/FirmwareConfigUpdateDxe/FirmwareConfigUpdateDxe.inf
  Platform/Radxa/Platforms/CIX/Sky1/Drivers/PlatformConfigDxe/PlatformConfigDxe.inf
  Platform/Radxa/Platforms/CIX/Sky1/Drivers/RadxaSetupVariableInitDxe/RadxaSetupVariableInitDxe.inf
  Platform/Radxa/Platforms/CIX/Sky1/Drivers/SeConfigUpdateDxe/SeConfigUpdateDxe.inf
  Platform/Radxa/Platforms/CIX/Sky1/Drivers/SystemInfoDxe/SystemInfoDxe.inf

  SecurityPkg/Tcg/Tcg2Dxe/Tcg2Dxe.inf {
    <LibraryClasses>
      HashLib|SecurityPkg/Library/HashLibBaseCryptoRouter/HashLibBaseCryptoRouterDxe.inf
      NULL|SecurityPkg/Library/Tpm2DeviceLibDTpm/Tpm2InstanceLibDTpm.inf
      NULL|SecurityPkg/Library/HashInstanceLibSha1/HashInstanceLibSha1.inf
      NULL|SecurityPkg/Library/HashInstanceLibSha256/HashInstanceLibSha256.inf
      NULL|SecurityPkg/Library/HashInstanceLibSha384/HashInstanceLibSha384.inf
  }
  SecurityPkg/VariableAuthenticated/SecureBootConfigDxe/SecureBootConfigDxe.inf
  SecurityPkg/VariableAuthenticated/SecureBootDefaultKeysDxe/SecureBootDefaultKeysDxe.inf

  ShellPkg/Application/Shell/Shell.inf {
    <LibraryClasses>
      ShellLib|ShellPkg/Library/UefiShellLib/UefiShellLib.inf
      ShellCommandLib|ShellPkg/Library/UefiShellCommandLib/UefiShellCommandLib.inf
      NULL|ShellPkg/Library/UefiShellLevel2CommandsLib/UefiShellLevel2CommandsLib.inf
      NULL|ShellPkg/Library/UefiShellLevel1CommandsLib/UefiShellLevel1CommandsLib.inf
      NULL|ShellPkg/Library/UefiShellLevel3CommandsLib/UefiShellLevel3CommandsLib.inf
      NULL|ShellPkg/Library/UefiShellDriver1CommandsLib/UefiShellDriver1CommandsLib.inf
      NULL|ShellPkg/Library/UefiShellDebug1CommandsLib/UefiShellDebug1CommandsLib.inf
      NULL|ShellPkg/Library/UefiShellInstall1CommandsLib/UefiShellInstall1CommandsLib.inf
      NULL|ShellPkg/Library/UefiShellAcpiViewCommandLib/UefiShellAcpiViewCommandLib.inf
      NULL|ShellPkg/Library/UefiShellNetwork1CommandsLib/UefiShellNetwork1CommandsLib.inf
      HandleParsingLib|ShellPkg/Library/UefiHandleParsingLib/UefiHandleParsingLib.inf
      BcfgCommandLib|ShellPkg/Library/UefiShellBcfgCommandLib/UefiShellBcfgCommandLib.inf
    <PcdsFixedAtBuild>
      gEfiShellPkgTokenSpaceGuid.PcdShellLibAutoInitialize|FALSE
      gEfiMdePkgTokenSpaceGuid.PcdUefiLibMaxPrintBufferSize|8000
      gEfiShellPkgTokenSpaceGuid.PcdShellFileOperationSize|0x200000
  }

  Silicon/CIX/Sky1/Drivers/CdnspDxe/CdnspDxe.inf {
    <LibraryClasses>
      UncachedMemoryAllocationLib|Silicon/CIX/Sky1/Library/UncachedMemoryAllocationLib/UncachedMemoryAllocationLib.inf
  }
  Silicon/CIX/Sky1/Drivers/ClockDxe/ClockDxe.inf
  Silicon/CIX/Sky1/Drivers/ConfigParamsManageDxe/ConfigParamsManageDxe.inf
  Silicon/CIX/Sky1/Drivers/DpuDxe/DpuDxe.inf
  Silicon/CIX/Sky1/Drivers/GenericWatchdogDxe/GenericWatchdogDxe.inf
  Silicon/CIX/Sky1/Drivers/I2cDxe/I2cDxe.inf
  Silicon/CIX/Sky1/Drivers/PcieInitDxe/PcieInitDxe.inf
  Silicon/CIX/Sky1/Drivers/PowerDxe/PowerDxe.inf
  Silicon/CIX/Sky1/Drivers/ResetDxe/ResetDxe.inf
  Silicon/CIX/Sky1/Drivers/RngDxe/RngDxe.inf
  Silicon/CIX/Sky1/Drivers/SocDxe/SocDxe.inf
  Silicon/CIX/Sky1/Drivers/SpiDxe/SpiDxe.inf
  Silicon/CIX/Sky1/Drivers/TypecPhyDxe/TypecPhyDxe.inf
  Silicon/CIX/Sky1/Drivers/Usb20HostDxe/Usb20HostDxe.inf
  Silicon/CIX/Sky1/Drivers/Usb32HostDxe/Usb32HostDxe.inf
  Silicon/CIX/Sky1/Drivers/UsbCHostDxe/UsbCHostDxe.inf

[BuildOptions]
  GCC:*_*_*_CC_FLAGS              = -fno-common
  GCC:*_*_*_CC_FLAGS              = -DCOMPILE_BUILD_DATE=$(BUILD_DATE)
!if $(TARGET) == RELEASE
  GCC:*_*_*_CC_FLAGS              = -DUEFI_FW_VERSION=9.0.3
!else
  GCC:*_*_*_CC_FLAGS              = -DUEFI_FW_VERSION=9.0.3"-"$(COMMIT_HASH)"-debug:"$(BUILD_DATE)
!endif
  GCC:DEBUG_*_*_CC_FLAGS          = -DDEBUG_MODE
  GCC:RELEASE_*_*_CC_FLAGS        = -DMDEPKG_NDEBUG -DNDEBUG
  GCC:*_*_*_CC_FLAGS              = -DFASTBOOT_NVME
  GCC:*_*_*_CC_FLAGS              = -DMULTICORE_ENABLE
  GCC:*_*_*_ASLCC_FLAGS           = -DMULTICORE_ENABLE
  GCC:*_*_*_ASLPP_FLAGS           = -DMULTICORE_ENABLE
  GCC:*_*_*_PP_FLAGS              = -DUPDATE_MEMORY_TOP
  GCC:*_*_*_CC_FLAGS              = -DUPDATE_MEMORY_TOP
  GCC:*_*_*_CC_FLAGS              = -DREBOOT_REASON_ENABLE
  GCC:*_*_*_CC_FLAGS              = -DPHYSICAL_PHY
  GCC:*_*_*_CC_FLAGS              = -DFV_MAIN_COMPRESSED
  GCC:*_*_*_CC_FLAGS              = -DDYNAMIC_ACPI_CPU_ENABLE
  GCC:*_*_*_ASLPP_FLAGS           = -DDYNAMIC_ACPI_CPU_ENABLE
  GCC:*_*_*_ASLPP_FLAGS           = -DDYNAMIC_ACPI_CPU_ENABLE
  GCC:*_*_*_ASLPP_FLAGS           = -DLINUX_ACPI_CONFIG_OVERRIDE
  GCC:*_*_*_ASLPP_FLAGS           = -I$(WORKSPACE)/../../common/cix-edk2-platforms/Platform/Radxa/Orion/O6/Drivers
  GCC:*_*_*_CC_FLAGS              = -DSTMM_SUPPORT
  GCC:*_*_*_VFRPP_FLAGS           = -DFW_CONFIG_UPDATE_SUPPORT=1

[BuildOptions.common.EDKII.DXE_RUNTIME_DRIVER]
  GCC:*_*_AARCH64_DLINK_FLAGS = -z common-page-size=0x10000
