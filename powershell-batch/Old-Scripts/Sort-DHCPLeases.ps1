Param(
[switch]$SortByName,
$ComputerName = "DHCP1"
)
$ErrorActionPreference = "Stop"
$FilePath = "$env:TEMP"
$XMLFileName = "$FilePath\DHCP.xml"
Export-DhcpServer -ComputerName $ComputerName -File $XMLFileName -Force
#notepad $XMLFileName

[xml]$xml = Get-Content -Path $XMLFileName
If ($SortByName -eq $True)
 {
  $sorted = $xml.DHCPServer.IPv4.Scopes.Scope.Reservations.Reservation | Sort-Object -Property { $_.Name }
 }
Else
 {
  $sorted = $xml.DHCPServer.IPv4.Scopes.Scope.Reservations.Reservation | Sort-Object -Property { [System.Version]$_.IPAddress }
 }

$lastChild = $sorted[-1]
$sorted[0..($sorted.Length-2)] | Foreach {$xml.DHCPServer.IPv4.Scopes.Scope.Reservations.InsertBefore($_,$lastChild)} | Out-Null
$xml.Save($XMLFileName)
Import-DhcpServer -ComputerName $ComputerName –File $XMLFileName –backuppath "$FilePath\DHCPBackup" -ver -ScopeOverwrite -Force

Write-Host "DHCP Config Backup located in $FilePath\DHCPBackup" -ForegroundColor Green -BackgroundColor Black

