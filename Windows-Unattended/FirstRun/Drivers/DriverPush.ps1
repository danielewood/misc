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

#$DriverPath = "$InvocationPath\$OS\$OSArchitecture\$Manufacturer"
$DriverPath = "$InvocationPath\$OS\$OSArchitecture\$Manufacturer\$Model"


if (Test-Path $DriverPath) {
	$infs = Get-ChildItem -Path $DriverPath -Filter "*.inf" -Recurse -File 
	foreach($inf in $infs){ 
	    $inf.FullName 
	    pnputil.exe -i -a ""$inf.FullName"" 
	}
}
