 param(
 #Domain Name to check (checks all subdomains)
 [string]$DomainName = 'contoso.org',

 #If True, keeps all times as UTC.
 #If False, local system time is used for display purposes.
 [switch]$UseUTCTime = $False,

 # Email SMTP Username 
 [string]$EmailUsername = "it.mailer@contoso.com", #Office365 account

 # Email SMTP Password 
 # Generate Secure String password using:
 # runas /user:CONTOSO\certbot powershell
 # "Password_Here" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
 # This MUST be run under the account that will be executing the script. The SecureString can only be decrypted by the account that creates it.
 # $EmailPassword = "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789" | ConvertTo-SecureString
 [string]$EmailPassword = "Plain-Text-Password",
 
 # Tells script if you entered the email password as Plain Text (default: $False) or a Secure String ($True)
 # Later on, if $EmailPasswordAsSecureString is $False, the script will convert the password to a secure string.
 [switch]$EmailPasswordAsSecureString = $False,

 # Email SMTP server
 [string]$SMTPServer = "smtp.office365.com",

 # Email FROM - Can be any distrobution group the login is allowed to send mail from.
 [string]$EmailFrom = "notifications@contoso.com",

 # Email TO
 [string]$EmailTo = "it@contoso.com",

 <# Uncomment to add CC and BCC, must also uncomment similar block at the end of the script.
 [string]$EmailBCC = "admin@contoso.com",
 [string]$EmailBCC = "admin@contoso.org",
 #>

 # Email subject
 [string]$EmailSubject = "New SSL Certificate issued for $DomainName",

 [string]$EmailPriority = "High",

 # Disable Using SSL/TLS for Email (Optional; $True/$False)
 [switch]$EmailDisableSSL = $False,

 # Email Port (Common Values: 25 for SMTP, 587 for SSL/TLS)
 [int]$EmailPort = 587

 )
 
$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"


If ($EmailPasswordAsSecureString -ne $True)
 {
 $EmailPassword = $EmailPassword | ConvertTo-SecureString -AsPlainText -Force
 }

$JSON = (Invoke-RestMethod -uri "https://certspotter.com/api/v0/certs?domain=$DomainName")
If ($JSON)
 {
 If ($UseUTCTime)
  {
  $JSON | ForEach-Object {$_.not_before = [DateTime]::SpecifyKind(([DateTime]::ParseExact($_.not_before,'yyyy-MM-dd\THH:mm:ss-00:00',$null)), [DateTimeKind]::Utc)}
  $JSON | ForEach-Object {$_.not_after = [DateTime]::SpecifyKind(([DateTime]::ParseExact($_.not_after,'yyyy-MM-dd\THH:mm:ss-00:00',$null)), [DateTimeKind]::Utc)}
  $JSON = $JSON | where not_before -gt (Get-Date).AddHours(-24).ToUniversalTime()
  $TimeZone = "(UTC)"
  }
 Else
  {
  $JSON | ForEach-Object {$_.not_before = ([DateTime]::SpecifyKind(([DateTime]::ParseExact($_.not_before,'yyyy-MM-dd\THH:mm:ss-00:00',$null)), [DateTimeKind]::Utc)).ToLocalTime()}
  $JSON | ForEach-Object {$_.not_after = ([DateTime]::SpecifyKind(([DateTime]::ParseExact($_.not_after,'yyyy-MM-dd\THH:mm:ss-00:00',$null)), [DateTimeKind]::Utc)).ToLocalTime()}
  $JSON = $JSON | Where not_before -gt (Get-Date).AddHours(-24)
  $TimeZone = ([System.TimeZoneInfo]::Local.DisplayName).substring(0,11)
  }
 
 $JSON | ForEach-Object {$_.not_before = '{0:yyyy-MM-dd\THH:mm:ss.DTGTZ}' -f $_.not_before }
 $JSON | ForEach-Object {$_.not_after = '{0:yyyy-MM-dd\THH:mm:ss.DTGTZ}' -f $_.not_after }
 $JSON | ForEach-Object {$_.dns_names = [string]$_.dns_names}

 $MessageBody =@()
 $JSON | ForEach-Object {
  $MessageBody = $MessageBody + ($_ | Select type, issuer, not_after, not_before | ConvertTo-Html -As List -Fragment).Replace('</table>','')
  $MessageBody = $MessageBody + ($_ | Select dns_names | ConvertTo-Html -As List -Fragment -Property dns_names).Replace(' ','<br>').Replace('<table>','')
  }
 $MessageBody = $MessageBody.Replace(".DTGTZ</td>"," $TimeZone</td>")
 $MessageBody = $MessageBody.Replace(".DTGTZ</td>"," $TimeZone</td>")
 $MessageBody = ConvertTo-Html -head $style -body $MessageBody | Out-String
 
 If ($JSON.issuer -eq "C=US, O=Let's Encrypt, CN=Let's Encrypt Authority X3")
  {
  $MessageBody = $MessageBody.Replace("<td>C=US, O=Let&#39;s Encrypt, CN=Let&#39;s Encrypt Authority X3</td>","<td><a href=`"https://www.google.com/transparencyreport/https/ct/#domain=$DomainName&incl_exp=false&incl_sub=true`">C=US, O=Let&#39;s Encrypt, CN=Let&#39;s Encrypt Authority X3</a></td>")
  $MessageBody = $MessageBody.Replace("<table>`r`n</table>","")
  }
 Else
  {
  $MessageBody = $MessageBody.Replace("</head><body>","</head><body><br>More Details: https://www.google.com/transparencyreport/https/ct/#domain=$DomainName&incl_exp=false&incl_sub=true")
  $MessageBody = $MessageBody.Replace("<table>`r`n</table>","")
  }

 $EmailCreds = New-Object System.Management.Automation.PSCredential ($EmailUsername,$EmailPassword)
 Send-MailMessage `
    -To $EmailTo `
     <#
    -CC:($EmailCC)}) `
    -BCC:($EmailBCC)}) `
     #> `
    -Subject:($EmailSubject) `
    -Body $MessageBody `
    -BodyAsHtml `
    -UseSsl:(!$EmailDisableSSL) `
    -Port $EmailPort `
    -SmtpServer $SMTPServer `
    -From $EmailFrom `
    -Priority $EmailPriority `
    -Credential $EmailCreds
 }
Else
 {
 Write-Host "No New Certificates"
 }
