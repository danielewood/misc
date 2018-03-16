#Run from Lync/Skype Edge Server:
Stop-Transcript
$CertFilename = "VPN-LE.pfx"
$CertPassword = "VPNk8gjl5d2fkmn1627e2d94ca2a500d1dff0cc38b0"
$CertSubject = "CN=vpn.contoso.com"
$CertPath = $($env:TEMP)
#$CertPath = 'C:\Lync'

$SSH_Username = "certbot"
$SSH_Password = '"xkcd style pass phrase goes here"' #Yes, double quotes to account for XKCD style passwords
$SSH_Hostname = "10.1.1.64"
$SSH_Path="/home/$SSH_Username/letsencrypt/$CertFilename"

$pscpPath = (Split-Path $MyInvocation.InvocationName) #By default, look for putty in the script directory



$CertFilename="$CertPath\$CertFilename"

$invalidChars = [io.path]::GetInvalidFileNamechars()
$datestampforfilename = ((Get-Date -format s).ToString() -replace "[$invalidChars]","-")
 
# Get the script path
$ScriptPath = (Split-Path $MyInvocation.InvocationName)
$ScriptName = [System.IO.Path]::GetFilenameWithoutExtension($MyInvocation.MyCommand.Path.ToString())
#$Logfile = "$ScriptName-$($datestampforfilename).txt"
$Logfile = "$ScriptName.log.txt"
#$Logfile = "$env:TEMP\$Logfile"
$Logfile = "C:\Lync\$Logfile"
 

#Start the logging
Start-Transcript $Logfile
Write-Output "Logging to $Logfile"

If ((Test-Path $pscpPath\pscp.exe) -eq $False)
 {
 Write-Warning "$pscpPath\pscp.exe does not exist, trying checking if it is installed in your installed path..."
 If ((Get-Command "pscp.exe" -ErrorAction SilentlyContinue).Path -eq $True)
  {
  Write-Output "Found Putty SCP in your installed path, using that instead."
  $pscpPath = (Split-Path (Get-Command "pscp.exe").Path)
  }
 Else
  {
  Write-Warning "Could not find pscp.exe in $pscpPath or as an installed program, exiting..."
  Stop-Transcript
  #& notepad.exe $Logfile
  exit
  }
}

Write-Output "Connecting to $SSH_Hostname and downloading $SSH_Path..."
& echo Y|&"$pscpPath\pscp.exe" -pw $SSH_Password $SSH_Username@$SSH_Hostname":"$SSH_Path $CertFilename
If ($LASTEXITCODE -eq 1)
 {
 Write-Warning "Putty SCP Failed to download file $SSH_Path to $CertFilename"
 Write-Output ('Parameters: ' + "$pscpPath\pscp.exe " + "-pw $SSH_Password $SSH_Username " + '@' + "$SSH_Hostname" + ':' + "$SSH_Path $CertFilename")
 Write-Warning "Exiting script..."
 Stop-Transcript
 #& notepad.exe $Logfile
 
 exit
 }
Else
 {Write-Output "Successfully downloaded $(Split-Path $SSH_Path -Leaf) to $CertFilename"}



$Certificate = Get-PfxData -FilePath $CertFilename -Password ($CertPassword | ConvertTo-SecureString -AsPlainText -Force)

$Thumbprint = $Certificate.EndEntityCertificates.Thumbprint

$EffectiveDate = ($Certificate.EndEntityCertificates.NotBefore).AddDays(2)



#If (!(get-childitem cert:\localMachine\my | where Thumbprint -eq $Thumbprint))
# {
 Import-PfxCertificate -Exportable:$True -Password ($CertPassword | ConvertTo-SecureString -AsPlainText -Force) -CertStoreLocation cert:\localMachine\my -FilePath $CertFilename -Verbose
 #Write-Output "Completed Certificate Installation";exit
 netsh http delete sslcert ipport=0.0.0.0:443
 netsh http delete sslcert ipport=[::]:443
 Remove-Item HKLM:\System\CurrentControlSet\Services\Sstpsvc\Parameters\Sha256CertificateHash
 Remove-Item HKLM:\System\CurrentControlSet\Services\Sstpsvc\Parameters\Sha1CertificateHash
 netsh http add sslcert ipport=0.0.0.0:443 certhash=$Thumbprint appid='{ba195980-cd49-458b-9e23-c84ee0adcd75}' certstorename=MY
 netsh http add sslcert ipport=[::]:443 certhash=$Thumbprint appid='{ba195980-cd49-458b-9e23-c84ee0adcd75}' certstorename=MY
 get-service RemoteAccess | Restart-Service
 Write-Output "Completed Certificate Installation"
<#}
Else
 {
  Write-Output "Already installed certificates are as follows:"
  get-childitem cert:\localMachine\my
  

  Write-Warning "Certificate you tried to install:"
  $Certificate.EndEntityCertificates | select Issuer,NotAfter,NotBefore,SerialNumber,Subject,@{n="AlternativeNames";e={$_.DnsNameList}},Thumbprint
  }
#>

If ($Certificate.EndEntityCertificates.Thumbprint)
 {
 Remove-Item $CertFilename -Force -Verbose
 }
Else
 {
 Write-Warning "Could not locate Certificate Thumbprint, the certificate is invalid or you supplied the wrong password"
 Write-Output "Reading Certificate:"
 (Get-PfxData -FilePath $CertFilename -Password ($CertPassword | ConvertTo-SecureString -AsPlainText -Force)).EndEntityCertificates
 }


# Stop logging
Stop-Transcript
Write-Output "Log File: $Logfile"
#& notepad.exe $Logfile

