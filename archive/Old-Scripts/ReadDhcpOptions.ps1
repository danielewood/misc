# 
# Name        : ReadDhcpOptions.ps1
# Author      : Ingmar Verheij - http://www.ingmarverheij.com
# Version     : 1.0, 12 july 2013
# Description : Shows the Dhcp options received by all Dhcp enabled NICs
# 

#http://www.sans.org/windows-security/2010/02/11/powershell-byte-array-hex-convert
function Convert-ByteArrayToString {
################################################################
#.Synopsis
# Returns the string representation of a System.Byte[] array.
# ASCII string is the default, but Unicode, UTF7, UTF8 and
# UTF32 are available too.
#.Parameter ByteArray
# System.Byte[] array of bytes to put into the file. If you
# pipe this array in, you must pipe the [Ref] to the array.
# Also accepts a single Byte object instead of Byte[].
#.Parameter Encoding
# Encoding of the string: ASCII, Unicode, UTF7, UTF8 or UTF32.
# ASCII is the default.
################################################################
[CmdletBinding()] Param (
 [Parameter(Mandatory = $True, ValueFromPipeline = $True)] [System.Byte[]] $ByteArray,
 [Parameter()] [String] $Encoding = "ASCII"
)
switch ( $Encoding.ToUpper() )
{
 "ASCII" { $EncodingType = "System.Text.ASCIIEncoding" }
 "UNICODE" { $EncodingType = "System.Text.UnicodeEncoding" }
 "UTF7" { $EncodingType = "System.Text.UTF7Encoding" }
 "UTF8" { $EncodingType = "System.Text.UTF8Encoding" }
 "UTF32" { $EncodingType = "System.Text.UTF32Encoding" }
 Default { $EncodingType = "System.Text.ASCIIEncoding" }
}
$Encode = new-object $EncodingType
$Encode.GetString($ByteArray)
}


#Fill an array with the "DHCP Message Type 53 values" from http://www.iana.org/assignments/bootp-dhcp-parameters/bootp-dhcp-parameters.xhtml
#(the dirty way)
$DhcpMessageType53Values+= @("")
$DhcpMessageType53Values+= @("DHCPDISCOVER")
$DhcpMessageType53Values+= @("DHCPOFFER")
$DhcpMessageType53Values+= @("DHCPREQUEST")
$DhcpMessageType53Values+= @("DHCPDECLINE")
$DhcpMessageType53Values+= @("DHCPACK")
$DhcpMessageType53Values+= @("DHCPNAK")
$DhcpMessageType53Values+= @("DHCPRELEASE")
$DhcpMessageType53Values+= @("DHCPINFORM")
$DhcpMessageType53Values+= @("DHCPFORCERENEW")
$DhcpMessageType53Values+= @("DHCPLEASEQUERY")
$DhcpMessageType53Values+= @("DHCPLEASEUNASSIGNED")
$DhcpMessageType53Values+= @("DHCPLEASEUNKNOWN")
$DhcpMessageType53Values+= @("DHCPLEASEACTIVE")
$DhcpMessageType53Values+= @("DHCPBULKLEASEQUERY")
$DhcpMessageType53Values+= @("DHCPLEASEQUERYDONE")


#Read dhcp-option information from CSV (ignore if the file can't be read)
try {$dhcpOptionDetails = @(); $dhcpOptionDetails = Import-Csv "DhcpOptions.csv" -Delimiter ";"} catch { }
try {$dhcpOptionVSDetails = @(); $dhcpOptionVSDetails = Import-Csv "DhcpOptionsVS.csv" -Delimiter ";" } catch { }

#Iterate through NIC's with IP obtained via DHCP
$objWin32NAC = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -namespace "root\CIMV2" -computername "." -Filter "IPEnabled = 'True' AND DHCPEnabled ='True'" 
foreach ($objNACItem in $objWin32NAC) 
{

	#Write adapter neame
	Write-Host -NoNewline -ForegroundColor White "Reading DHCP options of NIC "
	Write-Host -ForegroundColor Yellow $objNACItem.Caption 
	Write-Host ""

	#Write IP information
	Write-Host -NoNewline -ForegroundColor White "  IP address : " 
	Write-Host ((Get-ItemProperty -Path ("HKLM:\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\{0}" -f $objNACItem.SettingID) -Name DhcpIPAddress).DhcpIPAddress)
	Write-Host -NoNewline -ForegroundColor White "  DHCP server: " 
	
	#Write DHCP options
	Write-Host ((Get-ItemProperty -Path ("HKLM:\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\{0}" -f $objNACItem.SettingID) -Name DhcpServer).DhcpServer)
	Write-Host -ForegroundColor White "  Options    :" 
	
	#Read DHCP options
	$DhcpInterfaceOptions = (Get-ItemProperty -Path ("HKLM:\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\{0}" -f $objNACItem.SettingID) -Name DhcpInterfaceOptions).DhcpInterfaceOptions
	$DhcpOptions = @(); for ( $i = 0 ; $i -lt 256; $i++ ) { $DhcpOptions += @("") }
	$DhcpVendorSpecificOptions = @(); for ( $i = 0 ; $i -lt 256; $i++ ) { $DhcpVendorSpecificOptions += @("") }
	
	#Iterate through DHCP options
	$intPosition = 0
	while ($intPosition -lt $DhcpInterfaceOptions.length) 
	{
		#Read Dhcp code 
		$DhcpOptionCode = $DhcpInterfaceOptions[$intPosition]
		$intPosition = $intPosition + 8 #shift 8 bytes
		
		#Read length
		$DhcpOptionLength = $DhcpInterfaceOptions[$intPosition]
		$intPosition = $intPosition + 4 #shift 4 bytes
		
		#Is this a vendor specific option?
		$DhcpIsVendorSpecific = $DhcpInterfaceOptions[$intPosition]
		$intPosition = $intPosition + 4 #shift 4 bytes
		
		#Read "unknown data"
		$DhcpUnknownData = ""
		for ($i=0; $i -lt 4; $i++) { $DhcpUnknownData = $DhcpUnknownData + $DhcpInterfaceOptions[$intPosition + $i] }
		$intPosition = $intPosition + 4 #shift 4 bytes
		
		#Read value
		if (($DhcpOptionLength % 4) -eq 0) {$DhcpOptionBytesToRead = ($DhcpOptionLength - ($DhcpOptionLength % 4))} else {$DhcpOptionBytesToRead = ($DhcpOptionLength - ($DhcpOptionLength % 4)+4)}
		$DhcpOptionValue = New-Object Byte[] $DhcpOptionBytesToRead
		for ($i=0; $i -lt $DhcpOptionLength; $i++) { $DhcpOptionValue[$i] = $DhcpInterfaceOptions[$intPosition + $i] }
		$intPosition = $intPosition + $DhcpOptionBytesToRead #shift the number of bytes read
		
		
		#Add option to (vendor specific) array
		if ($DhcpIsVendorSpecific -eq 0)
		{
		   $DhcpOptions[$DhcpOptionCode] = $DhcpOptionValue
		} else {
		   $DhcpVendorSpecificOptions[$DhcpOptionCode] = $DhcpOptionValue
		}
	}
	
	#Show Dhcp Options
	for ( $i = 0 ; $i -lt 256; $i++ ) 
	{ 
		#Is this option 43 (vendor specific)?
		if ($i -ne 43)
		{
				$DhcpOptionIndex = $i
				$DhcpOptionValue = $DhcpOptions[$DhcpOptionIndex]
		
				if ($DhcpOptionValue) { 
					$dhcpOptionName = ($dhcpOptionDetails | Where-Object {$_.Code -eq $DhcpOptionIndex}).Name; if (-not [string]::IsNullOrEmpty($dhcpOptionName)) {$dhcpOptionName = (" ({0})" -f $dhcpOptionName)}
					$dhcpOptionType = ($dhcpOptionDetails | Where-Object {$_.Code -eq $DhcpOptionIndex}).Type; if ([string]::IsNullOrEmpty($dhcpOptionType)) {$dhcpOptionType = "unknown"}
					
					Write-Host -NoNewline ("  - {0}{1}: " -f $DhcpOptionIndex, ($dhcpOptionName))
					switch ($dhcpOptionType.ToLower())
					{
						"ip" {Write-Host ("{0}.{1}.{2}.{3}" -f ($DhcpOptionValue[0], $DhcpOptionValue[1], $DhcpOptionValue[2], $DhcpOptionValue[3]))}
						"string" {Write-Host (Convert-ByteArrayToString $DhcpOptionValue)}
						"time" { Write-host ("{0} seconds" -f [Convert]::ToInt32(($DhcpOptionValue[0].ToString("X2") + $DhcpOptionValue[1].ToString("X2") + $DhcpOptionValue[2].ToString("X2") + $DhcpOptionValue[3].ToString("X2")), 16) ) }
						"dhcpmsgtype" { Write-Host ("{0} ({1})" -f $DhcpOptionValue[0], $DhcpMessageType53Values[$DhcpOptionValue[0]])}
						default { Write-Host ($DhcpOptionValue | ForEach {$_.ToString("X2")}) }
					}
			}
		} else {
			Write-Host ("  - {0} (vendor specific)" -f $i)
			for ( $j = 0 ; $j -lt 256; $j++ ) 
			{
				$DhcpOptionIndex = $j
				$DhcpOptionValue = $DhcpVendorSpecificOptions[$DhcpOptionIndex]
							
				if ($DhcpOptionValue) { 
					$dhcpOptionName = ($dhcpOptionVSDetails | Where-Object {$_.Code -eq $DhcpOptionIndex}).Name; if (-not [string]::IsNullOrEmpty($dhcpOptionName)) {$dhcpOptionName = (" ({0})" -f $dhcpOptionName)}
					$dhcpOptionType = ($dhcpOptionVSDetails | Where-Object {$_.Code -eq $DhcpOptionIndex}).Type; if ([string]::IsNullOrEmpty($dhcpOptionType)) {$dhcpOptionType = "unknown"}
					
					Write-Host -NoNewline ("     - {0}{1}: " -f $DhcpOptionIndex, ($dhcpOptionName))
					switch ($dhcpOptionType.ToLower())
					{
						"ip" {Write-Host ("{0}.{1}.{2}.{3}" -f ($DhcpOptionValue[0], $DhcpOptionValue[1], $DhcpOptionValue[2], $DhcpOptionValue[3]))}
						"string" {Write-Host (Convert-ByteArrayToString $DhcpOptionValue)}
						"time" { Write-host ("{0} seconds" -f [Convert]::ToInt32(($DhcpOptionValue[0].ToString("X2") + $DhcpOptionValue[1].ToString("X2") + $DhcpOptionValue[2].ToString("X2") + $DhcpOptionValue[3].ToString("X2")), 16) ) }
						"dhcpmsgtype" { Write-Host ("{0} ({1})" -f $DhcpOptionValue[0], $DhcpMessageType53Values[$DhcpOptionValue[0]])}
						default { Write-Host ($DhcpOptionValue | ForEach {$_.ToString("X2")}) }
					}
				}
			}
		}
	}
	
	Write-Host ""
	Write-Host ""
	exit
}
