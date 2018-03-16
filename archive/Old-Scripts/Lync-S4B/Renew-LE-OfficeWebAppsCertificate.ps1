param(
[String]$CertFilename = "Skype-External.pfx",
[String]$CertPassword = "SKYPE00124a03de814a932a500d1dff0cc38b0",
[String]$CertSubject = "CN=sipexternal.contoso.com",
[String]$CertPath = $($env:TEMP),

[String]$SSH_Username = "certbot",
[String]$SSH_Password = '"xkcd style pass phrase goes here"', #Yes, double quotes to account for XKCD style passwords
[String]$SSH_Hostname = "certbot.contoso.com",
[String]$SSH_Path="/home/$SSH_Username/letsencrypt/$CertFilename"
)

$CertFilename="$CertPath\$CertFilename"

$invalidChars = [io.path]::GetInvalidFileNamechars()
$datestampforfilename = ((Get-Date -format s).ToString() -replace "[$invalidChars]","-")
 
# Get the script path
$ScriptPath = (Split-Path $MYInvocation.InvocationName)
$ScriptName = [System.IO.Path]::GetFilenameWithoutExtension($MYInvocation.MYCommand.Path.ToString())
$Logfile = "$ScriptName-$($datestampforfilename).txt"
$Logfile = "$env:TEMP\$Logfile"
 
# Start the logging
Start-Transcript $Logfile
Write-Output "Logging to $Logfile"

& "$ScriptPath\pscp.exe" -pw $SSH_Password $SSH_Username@$SSH_Hostname":"$SSH_Path $CertFilename 

$NewCert = Get-PfxData -FilePath $CertFilename -Password ($CertPassword | ConvertTo-SecureString -AsPlainText -Force)
#$NewCert.EndEntityCertificates.FriendlyName

If ($(Get-Item "IIS:\SslBindings\0.0.0.0!443").Thumbprint -eq $NewCert.EndEntityCertificates.Thumbprint)
 {
 Write-Host $NewCert.EndEntityCertificates
 Write-Warning "Certificate matches already bound certificate, exiting..."
 #Stop-Transcript;exit
 }


#-------------------------------------------------------------
Import-Module webadministration
Write-Output "Start Certificate Installation"
Write-Output "Deleting existing certificate from Store"

$certs = Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.subject -like "$CertSubject*" -AND $_.Subject -notmatch "CN=$env:COMPUTERNAME"}
foreach ($cert in $certs)
 {
 $Thumbprint = $cert.Thumbprint.ToString()
 If (Test-Path "cert:\localmachine\my\$Thumbprint")
  {
  Remove-Item -Path cert:\localmachine\my\$Thumbprint -DeleteKey
  }
 }

Write-Output "Running certutil to import certificate into Store"
$CertUtil = certutil.exe -f -importpfx -p $CertPassword $CertFilename
If ($CertUtil -match "FAILED") 
 {
    $CertUtil
    Write-Warning "CertUtil failed to import certificate"
    Write-Warning "Exiting..."
    Stop-Transcript
    #& notepad.exe $LogFile
    exit
 }

Write-Output "Locating the cert in the Store"
$cert = Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.subject -like "$CertSubject*"}
$Thumbprint = $cert.Thumbprint.ToString()

Remove-Item -path "IIS:\SSLBindings\*"

$WebSitePort = 443
$WebSiteName = "HTTP80"
Write-Output "Binding new SSL certificate to Site $WebSiteName listener on port $WebSitePort"
try
 {
 Remove-WebBinding -Name $WebSiteName -Port $WebSitePort -Protocol "https"
 New-WebBinding -Name $WebSiteName -Port $WebSitePort -Protocol "https"
 (Get-WebBinding $WebSiteName -Port $WebSitePort -Protocol "https").AddSslCertificate("$Thumbprint", "MY")
 }
catch
 {
 Write-Warning "Unable to bind cert to $WebSiteName listener on port $WebSitePort"
 }

If ((Get-OfficeWebAppsFarm).CertificateName)
 {

$WebSitePort = 810
$WebSiteName = "HTTP809"
Write-Output "Binding new SSL certificate to Site $WebSiteName listener on port $WebSitePort"
try
 {
 Remove-WebBinding -Name $WebSiteName -Port $WebSitePort -Protocol "https"
 New-WebBinding -Name $WebSiteName -Port $WebSitePort -Protocol "https"
 (Get-WebBinding $WebSiteName -Port $WebSitePort -Protocol "https").AddSslCertificate("$Thumbprint", "MY")
 }
catch
 {
 Write-Warning "Unable to bind cert to $WebSiteName listener on port $WebSitePort"
 $OWACertFail = $True
 }

}

If (!$OWACertFail)
 {
 Set-OfficeWebAppsFarm -CertificateName $NewCert.EndEntityCertificates.FriendlyName -Force
 }
Get-Item "IIS:\SslBindings\*" | Select IPAddress, Port, Thumbprint | ft -AutoSize
& {iisreset /noforce}
Get-Item "IIS:\SslBindings\*" | Select IPAddress, Port, Thumbprint | ft -AutoSize

Write-Output "Completed Certificate Installation"
 
# Stop logging
Stop-Transcript
#& notepad.exe $LogFile

