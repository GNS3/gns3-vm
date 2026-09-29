@echo off
title Running Admin PowerShell GNS3 VM script

:: Force Admin Elevation
net session >nul 2>&1
if %errorLevel% == 0 (
    powershell -ExecutionPolicy Bypass -File "%~dp0setup-vm.ps1"
) else (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
echo GNS3 VM installation script completed, please check the output above for any errors.
pause
