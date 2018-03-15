#Run from Lync/Skype OfficeWebApps Server:

param(
[String]$CertFilename = "Skype-External.pfx",
[String]$CertSubject = "CN=sipexternal.contoso.org",
[String]$CertPath = $($env:TEMP),
[String]$CertPassword = "SKYPECERTPASSWORD",

[String]$SSH_Username = "certbot",
[String]$SSH_Password = '"must engineer send help human"', #Yes, double quotes to account for XKCD style passwords
[String]$SSH_Hostname = "certbot.contoso.org",
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

& echo Y|& "$ScriptPath\pscp.exe" -pw $SSH_Password $SSH_Username@$SSH_Hostname":"$SSH_Path $CertFilename 


$NewCert = Get-PfxData -FilePath $CertFilename -Password ($CertPassword | ConvertTo-SecureString -AsPlainText -Force)

If ($($NewCert.EndEntityCertificates.FriendlyName) -ne $((Get-OfficeWebAppsFarm).CertificateName)){

Write-Output "Deleting existing certificate from Store"
try{
    $certs = Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.subject -like "$CertSubject*" -AND $_.Subject -notmatch "CN=$env:COMPUTERNAME"}
    foreach ($cert in $certs)
     {
     $Thumbprint = $cert.Thumbprint.ToString()
     If (Test-Path "cert:\localmachine\my\$Thumbprint")
      {
      Remove-Item -Path cert:\localmachine\my\$Thumbprint -DeleteKey
      }
     }
}
catch{
    Write-Warning "Unable to delete existing certificate from store"
    Write-Warning "Check certificate store to see if you have multiple certificates issued to $CertSubject."
}

Write-Output "Running certutil to import certificate into Store"
$CertUtil = certutil.exe -f -importpfx -p $CertPassword $CertFilename
If ($CertUtil -match "FAILED")
 {  $CertUtil

    Write-Warning "CertUtil failed to import certificate"

    Write-Warning "Exiting..."
    Stop-Transcript
    #& notepad.exe $LogFile
    exit
 }

New-OfficeWebAppsFarm -InternalUrl "https://OfficeWebApps.contoso.us" -ExternalUrl "https://OfficeWebApps.contoso.org" -CertificateName "$($NewCert.EndEntityCertificates.FriendlyName)" -EditingEnabled -Force -Confirm:$False

Write-Output "Completed Certificate Installation"
}
Else {
	Write-Output "$($NewCert.EndEntityCertificates.FriendlyName) is already installed"
}
Remove-Item $CertFilename -Force -Verbose
 
# Stop logging
Stop-Transcript
#& notepad.exe $LogFile

