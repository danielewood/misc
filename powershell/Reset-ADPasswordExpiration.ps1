function Reset-ADPasswordExpiration {
    <#
    .SYNOPSIS
Resets AD Password Expiration by changing date of pwdlastset to now.
    .DESCRIPTION
Resets AD Password Expiration by changing date of pwdlastset to now.
    .NOTES
Script by Daniel Wood (https://github.com/danielewood). Code is licened under Unlicense / CCZero / WTFPL / Public Domain.
    .LINK
https://github.com/danielewood/misc/tree/master/powershell
    .EXAMPLE
Get-ADUser -Filter {samaccountname -like 'dwoo*'} | Reset-ADPasswordExpiration -Verbose
VERBOSE: $Identity = CN=Daniel Wood,OU=Users,DC=contoso,DC=com
VERBOSE: Changed pwdlastset from 131753201305111407 to Now
VERBOSE: Changed pwdlastsetDate from 07/06/2018 03:08:50 to Now


DistinguishedName : CN=Daniel Wood,OU=Users,DC=contoso,DC=com
SamAccountName    : dwood
pwdlastset        : 131753201776369314
pwdlastsetDate    : 7/6/2018 3:09:37 AM
OLDpwdlastset     : 131753201305111407
OLDpwdlastsetDate : 7/6/2018 3:08:50 AM
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
