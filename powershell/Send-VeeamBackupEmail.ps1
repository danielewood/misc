Param( 
 ##################################################################
 #                   User Defined Variables
 ##################################################################
 
 # User Defined Variables have defaults listed below. You can modify the defaults or pass some/all them as parameters when calling the script.


 # Name of vCenter or standalone host VMs to backup (Mandatory)
 # When using -HostNames parameter, skip quotation marks around the host list if you wish to pass multiple hosts.
  # Valid: -HostNames HV1, HV2
  # Valid: -HostNames "HV1", "HV2"
  # Valid: -HostNames ("HV1", "HV2")
  # Invalid: -HostNames "HV1, HV2"
 [Parameter(
  ValueFromPipeline=$true,
  ValueFromPipelineByPropertyName=$true)]
 [Alias('ComputerName')]
 # When defining the array in the script, you must use the following format:
 # [array]$HostNames = ("HV1", "HV2"),
 #[array]$HostNames = ("HV1", "HV2", "HV3", "HV4", "HV5", "HV6", "HV7"),
  [array]$HostNames = ("HV7"),
 

 # Email SMTP Username 
 [string]$EmailUsername = "it.mailer@contoso.us", #Office365 account

 # Email SMTP Password 
 # Generate Secure String password using:
 # runas /user:CONTOSO\serviceaccount powershell
 # "Password_Here" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
 # This MUST be run under the account that will be executing the script. The SecureString can only be decrypted by the account that creates it.
 #$EmailPassword = "SecureString_here"| ConvertTo-SecureString
 [string]$EmailPassword = "text_goes_here",
 
 # Tells script if you entered the email password as Plain Text (default: $False) or a Secure String ($True)
 # Later on, if $EmailPasswordAsSecureString is $False, the script will convert the password to a secure string.
 [switch]$EmailPasswordAsSecureString = $False,

 # Email SMTP server
 [string]$SMTPServer = "smtp.office365.com",

 # Email FROM - Can be any distrobution group the login is allowed to send mail from.
 [string]$EmailFrom = "notifications@contoso.us",

 # Email TO
 [string]$EmailTo = "it@contoso.org",

 # Email subject
 [string]$EmailSubject = "Veeam Backup results for " + (Get-Date).ToString("yyyy-MM-dd @ HH:mm ") + [TimeZoneInfo]::Local.StandardName.Replace(" Standard Time",""),

 # Disable Using SSL/TLS for Email (Optional; $True/$False)
 [switch]$EmailDisableSSL = $False,

 # Email Port (Common Values: 25 for SMTP, 587 for SSL/TLS)
 [int]$EmailPort = 587,

 <# Uncomment to add CC and BCC, must also uncomment similar block at the end of the script.
 [string]$EmailBCC = "admin@contoso.com",
 [string]$EmailBCC = "admin@contoso.org",
 #>

 # Sets the maximum age (in hours) of the start time for VM Backups to report on.
 [int]$ReportHours = 28


 ##################################################################
 #                   End User Defined Variables
 ##################################################################
)

##################################################################
#                   Email formatting 
##################################################################

$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

#################### DO NOT MODIFY PAST THIS LINE ################



If ($EmailPasswordAsSecureString -ne $True)
 {
 [SecureString]$EmailPassword = $EmailPassword | ConvertTo-SecureString -AsPlainText -Force
 }
 else
 {
 [SecureString]$EmailPassword = $EmailPassword 
 }


# Error Checking # 
If ($HostNames -match ',')
 {
 Write-Host "WARNING: When using -HostNames parameter, skip quotation marks around the host list if you wish to pass multiple hosts." -ForegroundColor Yellow -BackgroundColor Black
 Write-Host 'Valid: -HostNames HV1, HV2' -ForegroundColor Green -BackgroundColor Black
 Write-Host 'Valid: -HostNames "HV1", "HV2"' -ForegroundColor Green -BackgroundColor Black
 Write-Host 'Valid: -HostNames ("HV1", "HV2")' -ForegroundColor Green -BackgroundColor Black
 Write-Host 'Invalid: -HostNames "HV1, HV2"' -ForegroundColor Red -BackgroundColor Black
 exit
 }
# Error Checking #

Add-PSSnapin VeeamPSSnapin

$MessageBody = @()
$MessageFail = @()

foreach ($HostName in $Hostnames)
 {
 $VMNames = Get-VM -ComputerName $HostName | Where ReplicationMode -notlike '*Replica' | Select-Object -ExpandProperty Name
 foreach ($VMName in $VMNames)
  {
  $VBRBackupSession = (Get-VBRBackupSession | where JobSpec -match "<VmName>$VMName</VmName>" | where CreationTime -gt (Get-Date).AddHours(-$ReportHours))
    $MessageBody = $MessageBody + ($VBRBackupSession `
     | Select-Object @{n="Name";e={($_.name).Substring(0, $_.name.LastIndexOf("("))}}, `
                     @{n="Host";e={($HostName)}}, `
                     @{n="Start Time";e={$_.CreationTime}}, `
                     @{n="End Time";e={$_.EndTime}}, `
                     @{n="Minutes";e={[int](New-TimeSpan -Start $_.CreationTime -End $_.EndTime).TotalMinutes}}, `
                     @{n="VmToolsQuiesce";e={[regex]::Match($_.JobSpec, '<VmToolsQuiesce>([^/)]+)</VmToolsQuiesce>').Groups[1].Value}}, `
                     Result)
  }
 }


$EmailPriority = "Normal"
If ($MessageBody.Result -match 'Failed')
 {
 $MessageFail = $MessageBody | Where Result -match 'Failed' | Sort Name | ConvertTo-Html -Fragment
 $EmailSubject = "FAILED " + $EmailSubject
 $EmailPriority = "High"
 }
 
 
$MessageBody = $MessageBody | Where Result -notmatch 'Failed' | Sort Name | ConvertTo-Html -Fragment
$MessageBody = $MessageFail + "<p></p>" + $MessageBody #| ConvertTo-Html -head $style | Out-String
$MessageBody = ConvertTo-Html -head $style -body $MessageBody | Out-String
$MessageBody = $MessageBody.Replace('Failed','<font color="red">Failed</font>')
$MessageBody = $MessageBody.Replace('Success','<font color="green">Success</font>')
$MessageBody = $MessageBody.Replace('<table>
</table>','')


#$MessageBody

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
   

