<##

Assuming appcmd is a console exe, even if it errors, the next line in the script will execute.

If you want to test if the EXE errored and the EXE uses the standard 0 exit code to indicate success, then just inspect the $? special variable right after calling the EXE. If it is $true, then the EXE returned a 0 exit code.

If the EXE is non-standard in terms of the exit code it returns for success (perhaps it has multiple success codes) then inspect $LastExitCode to get the exact exit code the last EXE returned.


#>


$Domain = "contoso.com"
$ComputerOUpath = "OU=Workstations,DC=contoso,DC=com" #Sets OU for all new computers.
$InventoryNum_MaxLength = 4 #Sets Maximum length for InventoryNumber

Write-Host "`n"`
"****************************************************** `n" `
"*   Contoso Domain Setup and Activation Script   * `n" `
"****************************************************** `n" -ForegroundColor "Yellow" -BackgroundColor "Black"
Write-Host " "

$Computer_Model = (Get-CimInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model)

if ($Computer_Model -eq "Virtual Machine")
    {
    $InventoryNumber = "VM"
    }
Else
    {

    do {
        Write-Host "Enter " -NoNewline  -BackgroundColor "Black"; `
        Write-Host "$InventoryNum_MaxLength-Digit" -NoNewline -ForegroundColor "Yellow" -BackgroundColor "Black"; `
        Write-Host " Inventory Number:" -BackgroundColor "Black" -NoNewline; `
        Write-Host " " -NoNewline
        $InventoryNumber=Read-Host
        $InventoryNumber=$InventoryNumber.SubString(0, [System.Math]::Min($InventoryNum_MaxLength, $InventoryNumber.Length)) # Truncates to MaxLength
        if ($InventoryNumber.Length -lt 2)
            {
            Write-Warning "You must enter at least two characters."
            }
    } until ($InventoryNumber.Length -ge 2)

}


$Computer_Model = (Get-CimInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model)
$Computer_OSCaption = (Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption)
$Computer_PCSystemType = (Get-CimInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty PCSystemType)

if ($Computer_Model -eq "Virtual Machine")
    {
    If ($Computer_OSCaption -like "*Server*")
        {
        $Computer_Type = "ServerVM"
        $Computer_Type_Index = 5
        }
    Else
        {
        $Computer_Type = "VM"
        $Computer_Type_Index = 6
        }
    }
Else
    {
    If ($Computer_PCSystemType -eq "2")
        {
        $Computer_Type = "Laptop"
        $Computer_Type_Index = 2
        }
    If ($Computer_PCSystemType -eq "1")
        {
        $Computer_Type = "Desktop"
        $Computer_Type_Index = 1
        }
    If ($Computer_OSCaption -like "*Server*")
        {
        $Computer_Type = "Server"
        $Computer_Type_Index = 4
        }
    If ($Computer_Model -like "*Surface*")
        {
        $Computer_Type = "Surface"
        $Computer_Type_Index = 3
        }
}
Write-Host $Computer_Type


$System_Type_Title = "System Type Selection"
$System_Type_Message = "<REPLACE THIS TEXT AT SOME POINT>"

$Server = New-Object System.Management.Automation.Host.ChoiceDescription "&Server", `
    "DHCPv4 Class ID = Server (Physical)"
$ServerVM = New-Object System.Management.Automation.Host.ChoiceDescription "Server (&VM)", `
    "DHCPv4 Class ID = ServerVM (Virtual Machine)"
$Desktop = New-Object System.Management.Automation.Host.ChoiceDescription "&Desktop", `
    "DHCPv4 Class ID = Desktop (Physical)"
$Laptop = New-Object System.Management.Automation.Host.ChoiceDescription "&Laptop", `
    "DHCPv4 Class ID = Laptop (Physical)"
$Surface = New-Object System.Management.Automation.Host.ChoiceDescription "S&urface", `
    "DHCPv4 Class ID = Laptop (Physical)"
$ClientVM = New-Object System.Management.Automation.Host.ChoiceDescription "&Client (VM)", `
    "DHCPv4 Class ID = VM (Virtual Machine)"

$System_Type_Options = [System.Management.Automation.Host.ChoiceDescription[]]($Desktop,$Laptop,$Surface,$Server,$ServerVM,$ClientVM) # (Order is critical to a default option and results in the switch below, do not change!)

$System_Type_Result = $host.ui.PromptForChoice($System_Type_Title, $System_Type_Message, $System_Type_Options, ($Computer_Type_Index-1))

switch ($System_Type_Result)
    {
        0 {$System_Type="Desktop"}
        1 {$System_Type="Laptop"}
        2 {$System_Type="Surface"}
        3 {$System_Type="Server"}
        4 {$System_Type="ServerVM"}
        5 {$System_Type="ClientVM"}
    }
Write-Host "Setting DHCP Option 77 User Class ID to $System_Type..."-ForegroundColor "Yellow" -BackgroundColor "Black"
$Set_System_Type = (ipconfig /setclassid * "$System_Type")
Write-Host "DHCP Option 77 User Class ID set to $System_Type"-ForegroundColor "Yellow" -BackgroundColor "Black"



$Computer_Model = $Computer_Model `
       -Replace 'Optiplex', 'OPT' `
       -Replace 'Latitude', 'LAT' `
       -Replace 'Surface with Windows 8 Pro', 'SUR' `
       -Replace 'Surface Pro 3', 'SUR3' `
       -Replace 'Surface Pro 4', 'SUR4' `
       -Replace 'Vostro', 'VOS' `
       -Replace 'PowerEdge', 'POW' `
       -Replace 'Precision', 'PRE' `
       -Replace 'PowerEdge', 'POW' `
       -Replace 'Inspiron', 'INS' `
       -Replace '-', '' `
       -Replace '\.', '' `
       -Replace ' ', '' #Removes Spaces


if ($Computer_Model -eq "VirtualMachine"){ #Replaces Model with OS Name and VM Serial Number
    $Computer_Model = (
        (Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption)`
        -Replace 'Microsoft Windows Server', 'S' `
        -Replace 'Microsoft Windows', 'W' `
        -Replace '2016', '16' `
        -Replace '2012 R2', '12' `
        -Replace 'Datacenter', 'D' `
        -Replace 'Standard', 'S' `
        -Replace 'Professional', 'P' `
        -Replace 'Pro', 'P' `
        -Replace 'Enterprise', 'E' `
        -Replace '-', '' `
        -Replace '\.', '' `
        -Replace ' ', '' ),
        (Get-CimInstance -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber).Replace('-','') -Join '-'
        }
        
$ComputerName_Generated = "$InventoryNumber-$Computer_Model"
$ComputerName_Generated = $ComputerName_Generated.SubString(0, [System.Math]::Min(15, $ComputerName_Generated.Length)) #Truncates computername to 15 characters or less.

do {
    $Loop_Pass = 1

    if (($NewComputerName = Read-Host "Enter Desired Computer Name [$ComputerName_Generated]") -eq '')
        {
        $NewComputerName = $ComputerName_Generated
        }

    if ($NewComputerName.Length -gt 15)
        {
        $NewComputerName = $NewComputerName.SubString(0, [System.Math]::Min(15, $NewComputerName.Length)) #Truncates computername to 15 characters or less.
        Write-Warning "You entered a Computer Name longer than 15 Characters. `nThe Computer Name will be truncated to: $NewComputerName.`n"
        $ComputerName_Generated = $NewComputerName
        $Loop_Pass = 0
        }

} while ($Loop_Pass -ne 1)

$User = Read-Host -Prompt "Enter your domain username"
$password = Read-Host -Prompt "Enter password for $User" -AsSecureString
$UserName = "$Domain\$User" 
$Credential = New-Object System.Management.Automation.PSCredential($UserName,$password)
Write-Host "Renaming computer to $NewComputerName..."
Rename-Computer -NewName $NewComputerName -WarningAction SilentlyContinue -ErrorAction Ignore -DomainCredential $Credential -Force
Write-Host "Joining domain $domain..."
Add-Computer -DomainName $Domain -Credential $Credential -NewName $NewComputerName -OUPath $ComputerOUpath -ErrorAction Ignore
Rename-Computer -NewName $NewComputerName -WarningAction SilentlyContinue -ErrorAction Ignore -DomainCredential $Credential -Force
Sleep 2
Rename-Computer -NewName $NewComputerName -WarningAction SilentlyContinue -ErrorAction Ignore -DomainCredential $Credential -Force

Write-Host "Now updating group policy..." -ForegroundColor "Yellow" -BackgroundColor "Black"
$gpupdate = (Invoke-Command -ScriptBlock { gpupdate /force })

if ($gpupdate -like "*Computer Policy update has completed successfully*.") {
    Write-Host "Computer Policy update has completed successfully." -ForegroundColor "Green" -BackgroundColor "Black"
     }
else {
    Write-Warning "Computer Policy update has failed"
     }
if ($gpupdate -like "*User Policy update has completed successfully*."){
    Write-Host "User Policy update has completed successfully." -ForegroundColor "Green" -BackgroundColor "Black"
     }
else {Write-Warning "User Policy update has failed"; Write-Host "Error Message is:"; Write-Host $gpupdate}



Write-Host "Activating Windows..." -ForegroundColor "Yellow" -BackgroundColor "Black"

if ((Invoke-Command -ScriptBlock { cscript \windows\system32\slmgr.vbs /ato }) -like "*Product activated successfully*")
    {
    Write-Host "Windows has Activated successfully." -ForegroundColor "Green" -BackgroundColor "Black"
     }
else {Write-Warning "Windows Activation Failed";Write-Host "Press Enter to Continue..." -NoNewline; Read-Host}

Write-Host "Activating Office 2013..." -ForegroundColor "Yellow" -BackgroundColor "Black"

if ((Invoke-Command -ScriptBlock { cscript \windows\system32\slmgr.vbs /ato b322da9c-a2e2-4058-9e4e-f59a6970bd69 }) -like "*Product activated successfully*")
    {
    Write-Host "Office has Activated successfully." -ForegroundColor "Green" -BackgroundColor "Black"
     }
else {Write-Warning "Office Activation Failed";Write-Host "Press Enter to Continue..." -NoNewline; Read-Host}


for ($a=10; $a -ne -1; $a--) {
  Write-Progress -Activity "Rebooting..." `
   -SecondsRemaining $a `
   -PercentComplete ($a*10)`
   -Status "Press CRTL+C to cancel reboot."
  Start-Sleep 1
}
Write-Warning "Rebooting..."
(Invoke-Command -ScriptBlock { shutdown -r -t 0 })