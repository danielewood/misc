# Unattended-Windows

## Use the boot.wim from Windows Server 2016

##FirstRun.cmd
 - Place in the install media: sources\$OEM$\$$\Setup\Scripts\FirstRun.cmd
 - Will be automatically placed into C:\Windows\Setup\Scripts on Windows install.
 - Automatically cycles through all drive letters searching for $Drive\FirstRun\FirstRun.bat and executes with Admin privilages on first run.
 
##FirstRun.bat
 - Place in the install media: $Drive\FirstRun\FirstRun.bat
 - Installs DotNet 4.6.2, Installs WMF5.1
    - These take place prior to displaying interactive session, so be patient on first boot.
  
##NoSleep.ps1
 - Place in the install media: $Drive\FirstRun\NoSleep.ps1
 - Moves mouse every 30 seconds to prevent screen saver during initial First boot install and update process.

##FirstRun.ps1
 - Place in the install media: $Drive\FirstRun\FirstRun.ps1
 - Runs custom powershell commands to install additional software, name computer, and join domain

##Autounattend.xml
 - Place in the install media root directory.
 - 64bit, EFI only
 - Will wipe and install on first hard drive in system
 - Creates Local Admin account and enables auto-login for next three boots.
 - Replace \<Value>Windows 8.1 Enterprise\</Value> with the correct image name for no-prompt installs.
 - Remove the \<InstallFrom> section for it to always prompt for all images available in the install.wim
