<#
  This script will import and bind a certificate to the Default
  Web Site for use with Lync/Skype Reverse Proxy, etc.

  Heavily modified from:
  http://www.jhouseconsulting.com/2015/01p04/script-to-import-and-bind-a-certificate-to-the-default-web-site-1548
  
  Syntax examples:
 
    Using hardcoded variables:
      Install-Certificate.ps1
 
    Passing parameters:
      Install-Certificate.ps1 -CertPath:"c:\temp\" -CertFilename:"star_jhouseconsulting_com.pfx" -CertPassword:"notT3LL1ngu" -CertSubject:"CN=*.jhouseconsulting.com"
 
    The ReplaceLocalServerCert is optional, and is forced to $False
    if left off. You really never want this set to true, especially
    if using a wildcard certificate. It's there mainly for flexibility.
 
    If the password contains a $ sign, you must escape it with the `
    character.
 
  Script Name: Install-IISCertificate.ps1
  
    A log file will be written to %LogPath%
     
#>
 

#-------------------------------------------------------------
param(
[String]$CertFilename = "Skype-External.pfx",
[String]$CertPassword = "SKYPECERTPASSWORD",
[String]$CertSubject = "CN=sipexternal.contoso.com",
[String]$CertPath = $($env:TEMP),

[String]$SSH_Username = "certbot",
[String]$SSH_Password = '"must engineer send help human"', #Yes, double quotes to account for XKCD style passwords
[String]$SSH_Hostname = "10.0.5.11",
[String]$SSH_Path="/home/$SSH_Username/letsencrypt/$CertFilename",

[switch]$ReplaceLocalServerCert=$False,
[switch]$ReallyReplaceLocalServerCert=$False,
[String]$WebSiteName = "Default Web Site",
$WebSitePort = 443
)

If ($ReplaceLocalServerCert -AND $ReallyReplaceLocalServerCert) {
Write-Warning "OK, you really want to replace the server certificate..."
Write-Warning "Waiting 10 seconds before continuing..."
sleep 10
}

$CertFilename="$CertPath\$CertFilename"


$invalidChars = [io.path]::GetInvalidFileNamechars()
$datestampforfilename = ((Get-Date -format s).ToString() -replace "[$invalidChars]","-")
 
# Get the script path
$ScriptPath = (Split-Path $MyInvocation.InvocationName)
$ScriptName = [System.IO.Path]::GetFilenameWithoutExtension($MyInvocation.MyCommand.Path.ToString())
$Logfile = "$ScriptName-$($datestampforfilename).txt"
$Logfile = "$env:TEMP\$Logfile"
 
# Start the logging
Start-Transcript $Logfile
Write-Output "Logging to $Logfile"

& "$ScriptPath\pscp.exe" -pw $SSH_Password $SSH_Username@$SSH_Hostname":"$SSH_Path $CertFilename 

$NewCert = Get-PfxData -FilePath $CertFilename -Password ($CertPassword | ConvertTo-SecureString -AsPlainText -Force)
If ($(Get-Item "IIS:\SslBindings\0.0.0.0!443").Thumbprint -eq $NewCert.EndEntityCertificates.Thumbprint)
{
Write-Host $NewCert.EndEntityCertificates
Write-Warning "Certificate matches already bound certificate, exiting..."
exit
}
#-------------------------------------------------------------

Write-Output "Start Certificate Installation"
 
Write-Output "Loading the Web Administration Module"
try{
    Import-Module webadministration
}
catch{
    Write-Output "Failed to load the Web Administration Module"
}
 
Write-Output "Deleting existing certificate from Store"
try{
    $cert = Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.subject -like "$CertSubject*" -AND $_.Subject -notmatch "CN=$env:COMPUTERNAME"}
    $Thumbprint = $cert.Thumbprint.ToString()
    If (Test-Path "cert:\localmachine\my\$Thumbprint") {
      Remove-Item -Path cert:\localmachine\my\$Thumbprint -DeleteKey
    }
}
catch{
    Write-Output "Unable to delete existing certificate from store"
}
 
Write-Output "Running certutil to import certificate into Store"
try{
    $ImportError = certutil.exe -f -importpfx -p $CertPassword $CertFilename
}
catch{
    Write-Output "certutil failed to import certificate: $ImportError"
}
 
Write-Output "Locating the cert in the Store"
try{
    If ($ReplaceLocalServerCert -AND $ReallyReplaceLocalServerCert) {
      Write-Warning "Tried to overwrite Machine cert, exiting..."
      exit
      #$cert = Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.subject -like "$CertSubject*" -AND $_.Subject -notmatch "CN=$env:COMPUTERNAME"}
    } Else {
      $cert = Get-ChildItem cert:\LocalMachine\My | Where-Object {$_.subject -like "$CertSubject*"}
    }
    $Thumbprint = $cert.Thumbprint.ToString()
    Write-Output $cert
}
catch{
    Write-Output "Unable to locate cert in certificate store"
}
 
Write-Output "Removing any existing binding from the site and SSLBindings store"
try{
  # Remove existing binding form site
  if ($null -ne (Get-WebBinding -Name $WebSiteName | where-object {$_.protocol -eq "https"})) {
    $RemoveWebBinding = Remove-WebBinding -Name $WebSiteName -Port $WebSitePort -Protocol "https"
    Write-Output $RemoveWebBinding
  }
  # Remove existing binding in SSLBindings store
  If (Test-Path "IIS:\SslBindings\0.0.0.0!$WebSitePort") {
    $RemoveSSLBinding = Remove-Item -path "IIS:\SSLBindings\0.0.0.0!$WebSitePort"
    Write-Output $RemoveSSLBinding
  }
}
catch{
    Write-Output "Unable to remove existing binding"
}
 
Write-Output "Bind your certificate to IIS HTTPS listener"
try{
  $NewWebBinding = New-WebBinding -Name $WebSiteName -Port $WebSitePort -Protocol "https"
  Write-Output $NewWebBinding
  $AddSSLCertToWebBinding = (Get-WebBinding $WebSiteName -Port $WebSitePort -Protocol "https").AddSslCertificate($Thumbprint, "MY")
  Write-Output $AddSSLCertToWebBinding
}
catch{
    Write-Output "Unable to bind cert"
}
 
Write-Output "Completed Certificate Installation"
 
# Stop logging
Stop-Transcript
