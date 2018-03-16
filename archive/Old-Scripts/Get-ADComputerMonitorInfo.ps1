Function Get-MonitorInfo
{
    [CmdletBinding()]
    Param
    (
        [Parameter(
        Position=0,
        ValueFromPipeLine=$true,
        ValueFromPipeLineByPropertyName=$true)]
        [string]$name = '.'
    )

    Process
    {

        $ActiveMonitors = Get-WmiObject -Query "Select * FROM WMIMonitorID" -Namespace root\wmi -ComputerName $name
        $monitorInfo = @()

        foreach ($monitor in $ActiveMonitors)
        {
            $mon = New-Object PSObject
            $manufacturer = $null
            $product = $null
            $serial = $null
            $name = $null
            $week = $null
            $year = $null

            $monitor.ManufacturerName | foreach {$manufacturer += [char]$_}
            $monitor.ProductCodeID | foreach {$product += [char]$_}
            $monitor.SerialNumberID | foreach {$serial += [char]$_}
            $monitor.UserFriendlyName | foreach {$name += [char]$_}

            $mon | Add-Member NoteProperty Manufacturer $manufacturer
            $mon | Add-Member NoteProperty ProductCode $product
            $mon | Add-Member NoteProperty SerialNumber $serial
            $mon | Add-Member NoteProperty Name $name
            $mon | Add-Member NoteProperty Week $monitor.WeekOfManufacture
            $mon | Add-Member NoteProperty Year $monitor.YearOfManufacture

            $monitorInfo += $mon
        }
        $monitorInfo
    }
}


$Inventory = @()
$Offline = @()
$ErrorComputer = @()
$time = (Get-Date).AddDays(-60)
ForEach ($ComputerName in $((Get-ADComputer -Filter { Enabled -eq $true -and LastLogonDate -gt $time }).DNSHostName)) {
    $InvError = "Online"
    If ($(Test-Connection $ComputerName -Quiet -Count 1)){
    $Inventory += Get-MonitorInfo $ComputerName -ErrorVariable InvError -ErrorAction SilentlyContinue | select @{n="ComputerName";e={($ComputerName)}}, @{n="Status";e={"Online"}}, Manufacturer,ProductCode,SerialNumber,Name,Week,Year
    #$Inventory += @(@{n="ComputerName";e={($ComputerName)}},@{n="Status";e={($InvError)}},Manufacturer,$_.ProductCode,$_.SerialNumber,$_.Name,$_.Week,$_.Year)
    if($InvError){$ErrorComputer += @($ComputerName,$InvError)}
    }
    Else{
    $Offline += $ComputerName
    }
    #$Inventory | ft
}
$Inventory | ft


