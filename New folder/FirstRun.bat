@ECHO OFF
PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "%~dp0NoSleep.ps1"' -Verb RunAs}"
REM Broken on Win10- use add-feature cmdlet instead "%~dp0Microsoft dot-NET Framework v3.5 SP1.exe" /q /norestart
"%~dp0NDP462-KB3151800-x86-x64-AllOS-ENU.exe" /q /norestart
"%~dp0WMF51-Win7AndW2K8R2-KB3191566-x64.msu" /quiet /norestart
"%~dp0WMF51-Win8.1AndW2K12R2-KB3191564-x64.msu" /quiet /norestart
PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "%~dp0FirstRun.ps1"' -Verb RunAs}"
