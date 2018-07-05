function Reset-ADPasswordExpiration {
    <#
    .SYNOPSIS
    Resets AD Password Expiration by changing date of pwdlastset to +30days or now, whichever is older.
    .DESCRIPTION
    Resets AD Password Expiration by changing date of pwdlastset to +30days or now, whichever is older.
    .NOTES
    Script by Daniel Wood (https://github.com/danielewood). Code is licened under Unlicense / CCZero / WTFPL / Public Domain.
    .LINK
    https://github.com/danielewood/misc/tree/master/powershell
    .EXAMPLE
Get-ADUser -Filter {samaccountname -like 'dwoo*'} | Reset-ADPasswordExpiration -ResetExtensionDays 90 -Verbose
    VERBOSE: CN=Daniel Wood,OU=Users,DC=contoso,DC=com
    VERBOSE: Changed pwdlastset from 131752961323435741 to Now


    DistinguishedName : CN=Daniel Wood,OU=Users,DC=contoso,DC=com
    SamAccountName    : dwood
    pwdlastset        : 131752961867300958
    pwdlastsetDate    : 7/5/2018 8:29:46 PM
    OLDpwdlastset     : 131752961323435741
    OLDpwdlastsetDate : 7/5/2018 8:28:52 PM

    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$True,
            ValueFromPipeline=$True,
            HelpMessage="SamAccopuntName or DistinguishedName")]
        [alias("SamAccountName","DistinguishedName")]
        [string[]] $Identity,
        
        [Parameter(Mandatory=$False,ValueFromPipeline=$False,HelpMessage="Number of days to extend expiration by")]
        [int] $ResetExtensionDays = 30,

        [Parameter(Mandatory=$False)]
        [switch] $WhatIf
        ) # end param
    begin {}
    process {
        foreach ($UserName in $Identity) {
            Write-Verbose $UserName
            $User = Get-ADUser -Identity "$UserName" -properties pwdlastset 
            $OldUser = $User
            $ResetTime = [datetime]::FromFileTimeUTC($User.pwdlastset).AddDays($ResetExtensionDays).ToFileTimeUTC()
            $Oldpwdlastset = $User.pwdlastset
            if ($ResetTime -lt [datetime]::Now.ToFileTimeUTC()){
                $User.pwdlastset = $ResetTime
                Set-ADUser -Instance $User -WhatIf:($WhatIf)
                Write-Verbose "Changed pwdlastset from $Oldpwdlastset to $($User.pwdlastset)"
            } else {
                $User.pwdlastset = 0 
                Set-ADUser -Instance $User -WhatIf:($WhatIf)
                $User.pwdlastset = -1 
                Set-ADUser -instance $User -WhatIf:($WhatIf)
                Write-Verbose "Changed pwdlastset from $Oldpwdlastset to Now"
            }
            Get-ADUser -Identity "$UserName" -properties pwdlastset | 
                Select DistinguishedName, SamAccountName, pwdlastset,
                @{ Label=”pwdlastsetDate”; Expression={[datetime]::FromFileTimeUTC($_.pwdlastset)} },
                @{ Label=”OLDpwdlastset”; Expression={$Oldpwdlastset} },
                @{ Label=”OLDpwdlastsetDate”; Expression={[datetime]::FromFileTimeUTC($Oldpwdlastset)} } 
        } # end foreach

    } # end process
    end {}
} # end function 
