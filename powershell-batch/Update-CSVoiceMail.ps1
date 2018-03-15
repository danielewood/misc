[string]$ServerPool = "lyncpoolfqdn.contoso.com"
[string]$CallAnswerWaitTime = "20"
[string]$OUPath = "*OU=Staff,OU=User Accounts,DC=contoso,DC=com"
[string]$VoicePrefix = "tel:+1222333*"

If (Test-Path "C:\Program Files\Microsoft Lync Server 2013\ResKit\SEFAUtil.exe")
 {
 $ResKitPath = "C:\Program Files\Microsoft Lync Server 2013\ResKit"
 }
If (Test-Path "C:\Program Files\Skype for Business 2015\ResKit\SEFAUtil.exe")
 {
 $ResKitPath = "C:\Program Files\Skype for Business 2015\ResKit"
 }
If ($ResKitPath -eq $False)
 {
 Write-Warning "Could not locate SEFAUtil.exe, exiting..."
 exit
 }

foreach ($User in (Get-CsUser | where Enabled -eq $True | where EnterpriseVoiceEnabled -eq $True | where Identity -like $OUPath | where LineURI -like $VoicePrefix))
 {
 $SefaIn = & "$ResKitPath\SEFAUtil.exe" /server:$($ServerPool) $User.SipAddress.Replace('sip:','')
 If (($SefaIn[4] -eq "CallForwarding Enabled: false") -Or ($SefaIn[4] -like "Forward immediate*"))
  {
  Write-Warning "Updating user $($User.DisplayName)"
  Write-Warning "Current settings:"
  $SefaIn
  Write-Warning "New settings:"
  & "$ResKitPath\SEFAUtil.exe" /enablefwdnoanswer /callanswerwaittime:"$CallAnswerWaitTime" /setfwddestination:$($User.LineURI.substring($User.LineURI.Length - 4, 4)) /server:$($ServerPool) $User.SipAddress.Replace('sip:','')
  }
 }
