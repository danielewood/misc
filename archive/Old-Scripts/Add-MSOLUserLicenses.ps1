Import-Module MSOnline 
$O365Cred = Get-Credential 
$O365Session = New-PSSession –ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $O365Cred -Authentication Basic -AllowRedirection 
Import-PSSession $O365Session -AllowClobber 
Connect-MsolService –Credential $O365Cred

$Unlicensed = $null
$Unlicensed = get-msoluser -all | where immutableid -ne $null | where MSRtcSipPrimaryUserAddress | where IsLicensed -eq $False
If ($Unlicensed) {
	ForEach ($UnlicensedUser in $Unlicensed) {
		#$UnlicensedUser | Set-Msoluserlicense -addlicenses (Get-MsolAccountSku).AccountSkuId
		$UnlicensedUser | Set-Msoluserlicense -addlicenses 'contosocom:STANDARDWOFFPACK'
	}
}
