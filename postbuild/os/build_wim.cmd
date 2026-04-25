
@echo off
setlocal

:: Switch to the directory where this script lives
cd /d "%~dp0"

:: Require the ISO drive letter as the first argument
if "%~1"=="" (
    echo Usage: %~nx0 ^<ISO_DRIVE_LETTER^>
    echo Example: %~nx0 E
    exit /b 1
)
set "ISO=%~1:"

:: Run the GenImage command script with proper arguments
%ISO%\GenImage\GenImage.cmd ^
    -PackagesList:O6_config.pkg ^
    -PackagePath:%ISO%\cabs ^
    -ImagePath:%ISO%\ ^
    -RegistryImport:O6_policy.reg ^
    -OutPath:build ^
    -wim ^
    -NoWait

:: ValidationOS-1.wim is the final output after removing dead/orphan space from the patching process
copy "build\ValidationOS-1.wim" "ODP_ValidationOS.wim"

endlocal
