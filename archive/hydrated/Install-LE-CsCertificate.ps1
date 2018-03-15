#Run from Lync/Skype Edge Server:

$CertFilename = "Skype-External.pfx"
$CertPassword = "SKYPECERTPASSWORD"
$CertPath = $($env:TEMP)

$SSH_Username = "certbot"
$SSH_Password = '"must engineer send help human"' #Yes, double quotes to account for XKCD style passwords
$SSH_Hostname = "10.0.5.11"
$SSH_Path="/home/$SSH_Username/letsencrypt/$CertFilename"
$pscpPath = (Split-Path $MyInvocation.InvocationName) #By default, look for putty in the script directory

$CertFilename="$CertPath\$CertFilename"

$invalidChars = [io.path]::GetInvalidFileNamechars()
$datestampforfilename = ((Get-Date -format s).ToString() -replace "[$invalidChars]","-")
 
# Get the script path
$ScriptPath = (Split-Path $MyInvocation.InvocationName)
$ScriptName = [System.IO.Path]::GetFilenameWithoutExtension($MyInvocation.MyCommand.Path.ToString())
$Logfile = "$ScriptName-$($datestampforfilename).txt"
$Logfile = "$env:TEMP\$Logfile"
 

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
  & notepad.exe $Logfile
  exit
  }
}

Write-Output "Connecting to $SSH_Hostname and downloading $SSH_Path..."
& "$pscpPath\pscp.exe" -pw $SSH_Password $SSH_Username@$SSH_Hostname":"$SSH_Path $CertFilename
If ($LASTEXITCODE -eq 1)
 {
 Write-Warning "Putty SCP Failed to download file $SSH_Path to $CertFilename"
 Write-Output ('Parameters: ' + "$pscpPath\pscp.exe " + "-pw $SSH_Password $SSH_Username " + '@' + "$SSH_Hostname" + ':' + "$SSH_Path $CertFilename")
 Write-Warning "Exiting script..."
 Stop-Transcript
 & notepad.exe $Logfile
 
 exit
 }
Else
 {Write-Output "Successfully downloaded $(Split-Path $SSH_Path -Leaf) to $CertFilename"}



$Certificate = Get-PfxData -FilePath $CertFilename -Password ($CertPassword | ConvertTo-SecureString -AsPlainText -Force)

$Thumbprint = $Certificate.EndEntityCertificates.Thumbprint

$EffectiveDate = ($Certificate.EndEntityCertificates.NotBefore).AddDays(2)

If ((Get-CSCertificate | where Use -like "*EdgeExternal" | where Thumbprint -ne $Thumbprint))
 {
 Write-Output "Completed Certificate Installation";exit
 Import-CsCertificate -Path $CertFilename -PrivateKeyExportable $True -Password $CertPassword -Verbose
 Set-CSCertificate -Type AccessEdgeExternal,DataEdgeExternal,AudioVideoAuthentication -Thumbprint $Thumbprint -EffectiveDate $EffectiveDate -Roll -Verbose
 Set-CSCertificate -Type XmppServer -Thumbprint $Thumbprint -EffectiveDate $EffectiveDate -Roll -Verbose
 Write-Output "Completed Certificate Installation"
 }
Else
 {
  Write-Output "Already installed certificates are as follows:"
  (Get-CSCertificate | where Use -ne "Internal")

  Write-Warning "Certificate you tried to install:"
  $Certificate.EndEntityCertificates | select Issuer,NotAfter,NotBefore,SerialNumber,Subject,@{n="AlternativeNames";e={$_.DnsNameList}},Thumbprint
  }
 

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
Write-Output "Logging to $Logfile"
#& notepad.exe $Logfile
