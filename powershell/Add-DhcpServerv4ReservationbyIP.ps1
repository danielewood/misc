Function Add-DhcpServerv4ReservationbyIP {
    <#
    .SYNOPSIS
    Automatically fills in MAC address for Add-DhcpServerv4Reservation cmdlet

    .DESCRIPTION
    Automatically fills in MAC address for Add-DhcpServerv4Reservation cmdlet

    .NOTES
    Script by Daniel Wood (https://github.com/danielewood). Code is licened under CCZero/WTFPL.

    .LINK
    https://github.com/danielewood/misc/tree/master/powershell

    .EXAMPLE
    Add-DhcpServerv4ReservationbyIP -ScopeId 10.54.0.0 -IPaddress 10.54.1.54
    VERBOSE: A new reservation with IP address 10.54.1.54 will be added in scope 10.54.0.0 on server WALSHDC01-VM.

    IPAddress            ScopeId              ClientId             Name                 Type                 Description         
    ---------            -------              --------             ----                 ----                 -----------         
    10.54.1.54           10.54.0.0            00-1a-4b-23-96-c9                         Both                                     

    .PARAMETER Description

    Sets description of DHCP Reservation

    #>

    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$True,
            ValueFromPipeline=$True,
            HelpMessage="DHCPv4 Reservation IP Address")]
        [System.Net.IPAddress] $IPAddress,

        [Parameter(Mandatory=$True,ValueFromPipeline=$True,HelpMessage="DHCPv4 ScopeID")]
        [System.Net.IPAddress] $ScopeId,

        [Parameter(Mandatory=$False,ValueFromPipeline=$True,HelpMessage="DHCPv4 Reservation Description")]
        [string] $Description,

        [Parameter(Mandatory=$False,ValueFromPipeline=$True,HelpMessage="DHCPv4 Server")]
        [Alias("ComputerName")]
        [string] $DHCPServer = $env:COMPUTERNAME,

        [Parameter(Mandatory=$False,ValueFromPipeline=$True,HelpMessage="DHCPv4 Reservation Name")]
        [string] $Name,

        [Parameter(Mandatory=$False)]
        [switch] $WhatIf,

        [Parameter(Mandatory=$False)]
        [switch] $Confirm
        )
    #Begin Script
    Test-Connection -Destination "$IPAddress" -Count 1 -ErrorAction SilentlyContinue | Out-Null
    $LinkLayerAddress = (Get-NetNeighbor -IPAddress "$IPAddress" -ErrorAction Stop).LinkLayerAddress
    Add-DhcpServerv4Reservation -ScopeId "$ScopeId" -IPAddress "$IPAddress" -ClientId "$LinkLayerAddress" -Description "$Description" -ComputerName "$DHCPServer" -Name "$Name" -WhatIf:$WhatIf -Confirm:$Confirm -Verbose
    Get-DhcpServerv4Reservation -ScopeId "$ScopeId" -ClientId "$LinkLayerAddress" -ComputerName "$DHCPServer"
}
