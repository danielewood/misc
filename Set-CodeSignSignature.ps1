param (
    [string]$FilePath = "", 
    [switch]$Force = $False,
    [switch]$WhatIf = $False,
    [switch]$Demonstration = $False
)

$SigningCert = $(Get-ChildItem cert:currentuser\my\ -CodeSigningCert)
$NumCerts=$($SigningCert | Measure-Object).Count

if ($NumCerts -eq 0) {
	Write-Output "No Signing Certs found!"
	exit 1
} else {
	if ( $NumCerts -gt 1) {
		$SigningCert = $SigningCert | Out-GridView -PassThru -Title "Select which Signing Certificate to use"
	}
		Write-Output "Using Signing Certificate:"; $SigningCert | Format-List
}

If ($FilePath) {
	$Files=Get-AuthenticodeSignature -FilePath $FilePath\*
} else {
	$Files=Get-AuthenticodeSignature *
}

$Files = $Files | Where-Object {($_.Status -eq 'NotSigned' -or $_.Status -eq 'HashMismatch')}

If ($Demonstration -eq $True){
  Write-Output 'Write-Output "This is a demonstration of a signed Powershell Script"' | Out-File $env:TEMP\Set-CodeSignSignatureDemoFile.ps1 -Force
  $Files = Get-AuthenticodeSignature -FilePath "$env:TEMP\Set-CodeSignSignatureDemoFile.ps1"
}


If ($Force) {
	Get-AuthenticodeSignature * | 
	Where-Object {($_.Status -eq 'NotSigned' -or $_.Status -eq 'HashMismatch')} |
	foreach {Set-AuthenticodeSignature $_.Path -Certificate $SigningCert -TimestampServer http://timestamp.digicert.com -Force -WhatIf:$WhatIf} 
} else {
	if ($Files.Count -eq 0) {
		Write-Output "No files to sign!"
	} else {
		if ( $Files.Count -gt 1) {
			$Files = $Files | Out-GridView -PassThru -Title "Select which items to sign"
		}
	}

	foreach ($File in $($Files.Path)) {
		Set-AuthenticodeSignature -FilePath $File -Certificate $SigningCert -TimestampServer http://timestamp.digicert.com -WhatIf:$WhatIf
	}
}

If ($Demonstration -eq $True){
	Write-Output "`n`nContents of $env:TEMP\Set-CodeSignSignatureDemoFile.ps1:`n`n"
	Get-Content $env:TEMP\Set-CodeSignSignatureDemoFile.ps1
}
