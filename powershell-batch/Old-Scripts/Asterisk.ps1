$FirstName = Read-Host -Prompt "Enter First Name"
$LastName = Read-Host -Prompt "Enter Last Name"
$EmployeeID = Read-Host -Prompt "Enter Employee ID"

function Convert-ToNumberRange {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Range of numbers in array.')]
        [int[]]$series
    )
    begin {
        $numberseries = @()
    }
    process {
        $numberseries += $series
    }
    end {
        $numberseries = @($numberseries | Sort-Object | Select-Object -Unique)
        $index = 1
        $initmode = $true
        # Start at the beginning
        $start = $numberseries[0]
        # If we only have a single number in the series, then go ahead and return it
        if ($numberseries.Count -eq 1) {
            return New-Object psobject -Property @{
                'Begin' = $numberseries[0]
                'End' = $numberseries[0]
            }
        }
        do {
            if ($initmode) {
                $initmode = $false
            }
            else {
                # If the current number minus the last number is not exactly 1, then the range has split
                # (so we have a non-contiguous series of numbers like 1,2,3,12,13,14….)
                if (($numberseries[$index] – $numberseries[$index – 1]) -ne 1) {
                    New-Object psobject -Property @{
                        'Begin' = $start
                        'End' = $numberseries[$index - 1]
                    }
                    # Reset our starting point and begin again
                    $start = $numberseries[$index]
                    $initmode = $true
                }
            }
            $index++
        }
       until ($index -eq ($numberseries.length))
        # We should always end up with a result at the end for the last digits
        New-Object psobject -Property @{
            'Begin' = $start
            'End' = $numberseries[$index – 1]
        }
    }
}

$AsteriskURL = "http://asterisk01.contoso.com"
$AsteriskUserName = "admin"
$AsteriskPassword = "a"
$EmailDomain = "contoso.com"

[string]$NewExtension = ""


$EmailAddress = "$FirstName.$LastName@$EmailDomain"
$AsteriskExtHref = 'config.php?type=&amp;display=extensions&amp;extdisplay='

$DisplayName = ("$FirstName $LastName").trim()


# Sends a sign-in request by running the Invoke-WebRequest cmdlet. The command specifies a value of "AsteriskSession" for the SessionVariable parameter, and saves the results in the $AsteriskData variable.

$AsteriskData = Invoke-WebRequest -Uri ("$AsteriskURL/admin/config.php") -SessionVariable AsteriskSession
if ($AsteriskData.Forms[0].id -eq "loginform") {
    $form = $AsteriskData.Forms[0]
    $form.Fields["username"] = $AsteriskUserName
    $form.Fields["password"] = $AsteriskPassword
    $AsteriskData = Invoke-WebRequest -Uri ("$AsteriskURL/admin/" + $form.Action) -WebSession $AsteriskSession -Method POST -Body $form.Fields
}
else {
    Write-Host "Asterisk Login form not found."
    end 
}
#End Sign In


$AsteriskData = Invoke-WebRequest -Uri ("$AsteriskURL/admin/config.php?display=extensions") -WebSession $AsteriskSession
$form = $AsteriskData.Forms[0]

$Numbers = $AsteriskData.Links | Where-Object {$_.href -like $($AsteriskExtHref + '5*')} | Select-Object `
                        @{n = "DisplayName"; e = {($_.innerText).Replace("<$(($_.href).Replace($AsteriskExtHref,''))>", '')}}, `
                        @{n = "Extension"; e = {($_.href).Replace($AsteriskExtHref, '')}}
$Numbers | Format-Table
$AvailExtension = @()
for ($i = 5100; $i -lt 5200; $i++) {
    if ($Numbers.Extension -notcontains $i) {$AvailExtension += $i}
}
    
for ($i = 5280; $i -lt 5300; $i++) {
    if ($Numbers.Extension -notcontains $i) {$AvailExtension += $i}
}

[string]$NewExtension = ""
if (!$NewExtension) {
    Write-Host "Available Extension Ranges:"
    $($AvailExtension | Convert-ToNumberRange) | Format-Table
    Write-Host "New user info:"
    Write-Host " FirstName = $FirstName"
    Write-Host "  LastName = $LastName"
    Write-Host "EmployeeID = $EmployeeID"
    do {
        $NewExtension = Read-Host -Prompt "Enter Four Digit Extension"
    }
    until ($NewExtension.Length -eq 4)
	#until ($NewExtension.Length -eq 4 -and $NewExtension[0] -eq "5")
} else {end}


$10DigitNumber = "222333" + $NewExtension

$AsteriskData = Invoke-WebRequest -Uri ("$AsteriskURL/admin/config.php?display=extensions") -WebSession $AsteriskSession
$form = $AsteriskData.Forms[0]

$form.Fields["display"] = "extensions"
$form.Fields["type"] = "virtual"
$form.Fields["action"] = "add"
$form.Fields["extdisplay"] = ""
$form.Fields["extension"] = "$NewExtension"
$form.Fields["name"] = "$FirstName $LastName"
$form.Fields["cid_masquerade"] = ""
$form.Fields["sipname"] = ""
$form.Fields["outboundcid"] = "$FirstName $LastName <$10DigitNumber>"
$form.Fields["ringtimer"] = "0"
$form.Fields["cfringtimer"] = "0"
$form.Fields["concurrency_limit"] = "0"
$form.Fields["callwaiting"] = "enabled"
$form.Fields["answermode"] = "disabled"
$form.Fields["call_screen"] = "0"
$form.Fields["pinless"] = "disabled"
$form.Fields["qnostate"] = "usestate"
$form.Fields["newdid_name"] = ""
$form.Fields["newdid"] = ""
$form.Fields["newdidcid"] = ""
$form.Fields["noanswer_dest"] = "goto0"
$form.Fields["busy_dest"] = "goto1"
$form.Fields["chanunavail_dest"] = "goto2"
$form.Fields["cc_agent_policy"] = "generic"
$form.Fields["cc_monitor_policy"] = "generic"
$form.Fields["dictenabled"] = "disabled"
$form.Fields["dictformat"] = "ogg"
$form.Fields["dictemail"] = ""
$form.Fields["langcode"] = ""
$form.Fields["recording_in_external"] = "recording_in_external=dontcare"
$form.Fields["recording_out_external"] = "recording_out_external=dontcare"
$form.Fields["recording_in_internal"] = "recording_in_internal=dontcare"
$form.Fields["recording_out_internal"] = "recording_out_internal=dontcare"
$form.Fields["recording_ondemand"] = "recording_ondemand=disabled"
$form.Fields["recording_priority"] = "10"
$form.Fields["userman%7Cassign"] = "none"
$form.Fields["vm"] = "enabled"
$form.Fields["vmpwd"] = "$EmployeeID"
$form.Fields["email"] = "$FirstName.$LastName@$EmailDomain"
$form.Fields["pager"] = ""
$form.Fields["attach"] = "attach=yes"
$form.Fields["saycid"] = "saycid=no"
$form.Fields["envelope"] = "envelope=no"
$form.Fields["delete"] = "delete=yes"
$form.Fields["options"] = ""
$form.Fields["vmcontext"] = "default"
$form.Fields["isymphony_add_email"] = ""
$form.Fields["isymphony_add_cell_phone"] = ""
$form.Fields["isymphony_jabber_host"] = ""
$form.Fields["isymphony_jabber_domain"] = ""
$form.Fields["isymphony_jabber_resource"] = "iSymphony"
$form.Fields["isymphony_jabber_port"] = "5222"
$form.Fields["isymphony_jabber_user_name"] = ""
$form.Fields["isymphony_jabber_password"] = ""
$form.Fields["isymphony_profile_password"] = "secret"
$form.Fields["cxpanel_add_extension"] = "0"
$form.Fields["cxpanel_auto_answer"] = "0"
$form.Fields["vmx_state"] = ""
$form.Fields["vmx_option_0_system_default"] = "checked"
$form.Fields["goto0"] = ""
$form.Fields["noanswer_cid"] = ""
$form.Fields["goto1"] = ""
$form.Fields["busy_cid"] = ""
$form.Fields["goto2"] = ""
$form.Fields["chanunavail_cid"] = ""
$form.Fields["Submit"] = "Submit"

#Delete Old Extension, if exists
$AsteriskData = Invoke-WebRequest -Uri ("$AsteriskURL/admin/config.php?type=&display=extensions&extdisplay=$NewExtension&action=del") -WebSession $AsteriskSession -Headers @{"Referer" = "$AsteriskURL/admin/config.php?"}
#Create New Extension
$AsteriskData = Invoke-WebRequest -Uri ("$AsteriskURL" + $form.Action) -WebSession $AsteriskSession -Method POST -Body $form.Fields -Headers @{"Referer" = "$AsteriskURL/admin/config.php?"}


$AsteriskData = Invoke-WebRequest -Uri ("$AsteriskURL/admin/config.php?display=extensions") -WebSession $AsteriskSession
$form = $AsteriskData.Forms[0]

$Numbers = $AsteriskData.Links | Where-Object {$_.href -like $($AsteriskExtHref + '5*')} | Select-Object `
                        @{n = "DisplayName"; e = {($_.innerText).Replace("<$(($_.href).Replace($AsteriskExtHref,''))>", '').Trim()}}, `
                        @{n = "Extension"; e = {($_.href).Replace($AsteriskExtHref, '').Trim()}}

ForEach ($Number in $Numbers) {
    If ($Number.Extension -eq $NewExtension -and $Number.DisplayName -eq $("$FirstName $LastName")) {
        Write-Host "Added $NewExtension"
        $AsteriskData = Invoke-WebRequest -Uri ("$AsteriskURL/admin/config.php?handler=reload") -WebSession $AsteriskSession
    }
}

