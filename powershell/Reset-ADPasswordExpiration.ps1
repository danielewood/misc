function Reset-ADPasswordExpiration {
<#
.SYNOPSIS
Resets AD Password Expiration by changing date of pwdlastset to now.

.DESCRIPTION
Resets AD Password Expiration by changing date of pwdlastset to now.

.NOTES
Script by Daniel Wood (https://github.com/danielewood).
Code is licened under Unlicense / CCZero / WTFPL / Public Domain.

.LINK
https://github.com/danielewood/misc/tree/master/powershell

.EXAMPLE
Reset-ADPasswordExpiration -SamAccountName dwood -Verbose
VERBOSE: $Identity = dwood
VERBOSE: Changed pwdlastset from 131615616553652266 to Now
VERBOSE: Changed pwdlastsetDate from 1/27/2018 21:20:55 to Now


DistinguishedName : CN=Daniel Wood,OU=Users,DC=contoso,DC=com
SamAccountName    : dwood
pwdlastset        : 131753201776369314
pwdlastsetDate    : 7/6/2018 3:09:37 AM
OLDpwdlastset     : 131615616553652266
OLDpwdlastsetDate : 1/27/2018 9:20:55 PM

.EXAMPLE
Get-ADUser -Filter {samaccountname -like 'dwoo*'} | Reset-ADPasswordExpiration
DistinguishedName : CN=Daniel Wood,OU=Users,DC=contoso,DC=com
SamAccountName    : dwood
pwdlastset        : 131753201776369314
pwdlastsetDate    : 7/6/2018 3:09:37 AM
OLDpwdlastset     : 131615616553652266
OLDpwdlastsetDate : 1/27/2018 9:20:55 PM

DistinguishedName : CN=David Woodard,OU=Users,DC=contoso,DC=com
SamAccountName    : dwoodard
pwdlastset        : 131753201776369314
pwdlastsetDate    : 7/6/2018 3:09:37 AM
OLDpwdlastset     : 131649253057717289
OLDpwdlastsetDate : 3/7/2018 7:41:45 PM
#>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$True,
            ValueFromPipeline=$True,
            HelpMessage="SamAccountName or DistinguishedName")]
        [alias("SamAccountName","DistinguishedName")]
        [string[]] $Identity,
        
        [Parameter(Mandatory=$False)]
        [switch] $WhatIf
        ) # end param
    begin {}
    process {
        $User = Get-ADUser -Identity "$Identity" -properties pwdlastset 
        $Oldpwdlastset = $User.pwdlastset

        Write-Verbose "`$Identity = $Identity"    
        Write-Debug "`$User = $User"
        Write-Debug "`$Oldpwdlastset = $Oldpwdlastset"

        $User.pwdlastset = 0 
        Set-ADUser -Instance $User -WhatIf:($WhatIf)
        $User.pwdlastset = -1 
        Set-ADUser -instance $User -WhatIf:($WhatIf)
        
        Write-Verbose "Changed pwdlastset from $Oldpwdlastset to Now"
        Write-Verbose "Changed pwdlastsetDate from $([datetime]::FromFileTimeUTC($Oldpwdlastset)) to Now"
        
        Get-ADUser -Identity "$Identity" -properties pwdlastset | 
            Select DistinguishedName, SamAccountName, pwdlastset,
            @{ Label=”pwdlastsetDate”; Expression={[datetime]::FromFileTimeUTC($_.pwdlastset)} },
            @{ Label=”OLDpwdlastset”; Expression={$Oldpwdlastset} },
            @{ Label=”OLDpwdlastsetDate”; Expression={[datetime]::FromFileTimeUTC($Oldpwdlastset)} } 
    } # end process
    end {}
} # end function 
