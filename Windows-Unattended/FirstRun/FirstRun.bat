:: @ECHO OFF
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 00000001 /f
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /Source:%~d0\sources\sxs

:: Get Updated MSUs from:
:: 1709: https://www.catalog.update.microsoft.com/Search.aspx?q=1709%20Cumulative%20x64
"%~dp0windows10.0-kb4090913-x64-1709-2018-03-Cumulative-Update.msu" /quiet /norestart

:: 1703: https://www.catalog.update.microsoft.com/Search.aspx?q=1703%20Cumulative%20x64
:: "%~dp0windows10.0-kb4092077-x64_1703-2018-03-Cumulative-Update.msu" /quiet /norestart

:: 1607 (LTSB 2016): https://www.catalog.update.microsoft.com/Search.aspx?q=1607%20Cumulative%20x64
:: "%~dp0windows10.0-kb4077525-x64_1607-2018-02-Cumulative-Update.msu" /quiet /norestart




wmic useraccount where (DOMAIN="%computername%" and  Name='default') set PasswordExpires='FALSE'
:: wmic useraccount where (DOMAIN="%computername%" and  Name='default') set PasswordChangeable='FALSE'

:: Imports all model specific drivers from the USB drive
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Drivers\DriverPush.ps1" -Verb RunAs

:: Office 365 Single User Licensing
%~dp0Office365\setup.exe /configure %~dp0Office365\default.xml

:: Office 365 Shared Licensing (Temporary license, does not permanently activate computer or take away from user's 5 activations)
:: %~dp0Office365\setup.exe /configure %~dp0Office365\shared.xml


:: Only use these commented out settings on desktops.
:: echo Setting High Performance Power Profile (Never Sleep)
:: powercfg.exe /SETACTIVE SCHEME_MIN
:: echo Disabling Hibernate Entirely
:: powercfg.exe /HIBERNATE OFF

:: set monitor sleep time to 30 mins
powercfg.exe -change -monitor-timeout-ac 30
:: powercfg.exe -change -monitor-timeout-dc 30

:: set disk sleep time to never
powercfg.exe -change -disk-timeout-ac 0
:: set disk sleep time to 5 minutes on battery
powercfg.exe -change -disk-timeout-dc 5

:: set computer sleep time to never
powercfg.exe -change -standby-timeout-ac 0
:: set computer sleep time to 60 minutes on battery
powercfg.exe -change -standby-timeout-dc 60

:: set computer hibernate time to never
powercfg.exe -change -hibernate-timeout-ac 0
:: set computer hibernate time to 5 hours on battery
powercfg.exe -change -hibernate-timeout-dc 300

:: set LID/Sleep button to Do Nothing on AC
powercfg.exe -setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg.exe -setacvalueindex SCHEME_CURRENT SUB_BUTTONS SBUTTONACTION 0
:: set power button to shutdown on AC
powercfg.exe -setacvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 3

:: Leave commented out to not change default behavior when on battery power
:: powercfg.exe -setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
:: powercfg.exe -setdcvalueindex SCHEME_CURRENT SUB_BUTTONS SBUTTONACTION 0
:: powercfg.exe -setdcvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 3

:: System shortcut on Default Admin desktop for easy access to Rename/Join Domain
copy %~dp0System.lnk %USERPROFILE%\Desktop\

:: Exports all drivers to the USB drive
:: PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Drivers\DriverCollector.ps1" -Verb RunAs

:: Enables Remote Desktop and Updates Windows/Office
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0FirstRun.ps1" -Verb RunAs

:: Installs Lenovo Utilities
%~dp0SystemInterfaceFoundation.exe /SILENT /NORESTART
%~dp0systemupdate5.07.0070.exe /SILENT /NORESTART
start %~dp0LENOVOHOTKEY\setup.bat
ping -n 10 localhost > NUL

%~dp0SophosEndpointNonInteractive.exe
"%~dp0E80.81_CheckPointVPN.msi" /passive /norestart

%~dp0LenovoAPS.msi /qn

shutdown -r -t 120

ECHO DONE
PAUSE
