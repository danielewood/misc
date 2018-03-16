[string]$Server = "toolbox.contoso.com"
[string]$RemoteFile = "/home/certbot/letsencrypt/Lync-Edge-External.pfx"
[string]$LocalFile = "$env:USERPROFILE\Desktop\Lync-Edge-External.pfx"
[string]$SSHUser = "certbot"
[string]$SSHPassword = "xkcd style pass phrase goes here"
[Security.SecureString]$CertPassword = ("00124a03de814a932a500d1dff0cc38b0" | ConvertTo-SecureString -AsPlainText -Force)

$RemoteFile = $RemoteFile.Replace('.pfx','') 
$LocalFile = $LocalFile.Replace('.pfx','')
$RemoteFile = "$Server" + ':' + "$RemoteFile"
& 'C:\Program Files (x86)\Putty\pscp.exe' -l $SSHUser -pw $SSHPassword -batch -q "$RemoteFile.MD5" "$LocalFile.MD5"

If ((Get-FileHash "$LocalFile.pfx" -Algorithm MD5).Hash -ieq (Get-Content "$LocalFile.MD5"))
 {
 Write-Host "Cert is unchanged, exiting"
 exit
 }
& "C:\Program Files (x86)\Putty\pscp.exe" -l $SSHUser -pw $SSHPassword -batch -q "$RemoteFile.pfx" "$LocalFile.pfx"
$NewCert = (Get-PfxData "$LocalFile.pfx" -Password $CertPassword).EndEntityCertificates

#Write-Host "Import-CS"
Import-CsCertificate -Path "$LocalFile.pfx" -PrivateKeyExportable $True -Password $CertPassword

#LynceEdge: Internal, AccessEdgeExternal, DataEdgeExternal, AudioVideoAuthentication
#LyncFE: Default, WebServicesInternal, WebServicesExternal, OAuthTokenIssuer

Set-CsCertificate -Type Default, WebServicesInternal, WebServicesExternal, OAuthTokenIssuer, Internal, AccessEdgeExternal, DataEdgeExternal, AudioVideoAuthentication -Thumbprint $NewCert.Thumbprint -Roll -EffectiveDate $NewCert.NotBefore.AddDays(10)
#Set-CsCertificate -Type AudioVideoAuthentication -Thumbprint $NewCert.Thumbprint -Roll -EffectiveDate $Newcert.NotBefore.AddDays(7)