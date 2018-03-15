$InvocationPath = Split-Path -parent $PSCommandPath
$InvocationPath
$WMI_OS = gwmi win32_operatingsystem
$WMI_CS = gwmi win32_computersystem

$OS = $WMI_OS.caption
If ($($WMI_OS.caption) -like "Microsoft Windows 10*"){$OS = "Microsoft Windows 10"}
$OSArchitecture = $WMI_OS.OSArchitecture
$Manufacturer = $WMI_CS.manufacturer
#$Model = $WMI_CS.systemfamily
$Model = $($WMI_CS.Model)
If ($($WMI_CS.manufacturer) -like "LENOVO"){$Model = $Model.substring(0,4)}

$TODAY = Get-Date -Format 'yyyy-MM-dd'

$DriverPath = "$InvocationPath\$OS\$OSArchitecture\$Manufacturer\$Model"
$DriverListPath = "$DriverPath\driver_list_$TODAY.txt"


if (Test-Path $DriverListPath) {
    echo "I have already got the drivers for this $Manufacturer $Model today I am going to skip it!"
    } else {
    new-item -Path $DriverPath -ItemType Directory
    Export-WindowsDriver -Destination "$DriverPath" -Online |
    Sort-Object classdescription |
    ft providername, version, date -GroupBy classdescription |
    out-file -FilePath "$DriverListPath"
    Get-ChildItem -Path $DriverPath | Where PSIsContainer -eq $True | Where Name -like "prnms0*" | Remove-Item -Force -Recurse #Remove MS Printer Drivers


    }

