##################################################################
#                   User Defined Variables
##################################################################


# Name of vCenter or standalone host VMs to backup reside on (Mandatory)
# Name must match server name in Veeam Console, it is not necessarily the Server's HostName.
$HostNames = "HV1", "HV2", "HV3", "HV4", "HV5", "HV6", "HV7"
#$HostNames = "HV7"

# Desired compression level (Optional; Possible values: 0 - None, 4 - Dedupe-friendly, 5 - Optimal, 6 - High, 9 - Extreme) 
$CompressionLevel = "4"

# Quiesce VM when taking snapshot (Optional; VMware Tools are required; Possible values: $True/$False)
# This setting may cause Generation 2 Linux VMs to fail.
# Disable "Backup (Volume Checkpoint)" in Hyper-V integration services if your Linux VM fails to backup.
# This will take crash-consistent backups for those Linux VMs
$EnableQuiescence = $True

# Protect resulting backup with encryption key (Optional; $True/$False)
$EnableEncryption = $False

# Encryption Key (Optional; path to a secure string)
$EncryptionKey = ""

# Retention settings (Optional; By default, VeeamZIP files are not removed and kept in the specified location for an indefinite period of time. 
# Possible values: Never , Tonight, TomorrowNight, In3days, In1Week, In2Weeks, In1Month)
$Retention = "Never"

# Root Path that VM backups should go to (Mandatory; for instance, C:\Backup)
$Path = "E:\Backup\Daily" #No Trailing \

#Starts all backup jobs in the background.
$EnableAsync = $True

##################################################################
#                   End User Defined Variables
##################################################################

#################### DO NOT MODIFY PAST THIS LINE ################
Add-PSSnapin VeeamPSSnapin

foreach ($HostName in $Hostnames)
{
# Directory that VM backups should go to (Mandatory; for instance, C:\Backup)
$Directory = "$Path\$HostName"

# Names of VMs to backup separated by comma (Mandatory). For instance, $VMNames = “VM1”,”VM2”
# $VMNames = "*"
# Get all non-replica VMs on host:
$VMNames = Get-VM -ComputerName $HostName | Where State –eq ‘Running’ | Select-Object -ExpandProperty Name

  foreach ($VMName in $VMNames)
  {
      $Server = Get-VBRServer -name $HostName
      $VM = Find-VBRHvEntity -Name $VMName -Server $Server
      
      If ($EnableEncryption)
      {
        $EncryptionKey = Add-VBREncryptionKey -Password (cat $EncryptionKey | ConvertTo-SecureString)
        $ZIPSession = Start-VBRZip -Entity $VM -Folder $Directory -Compression $CompressionLevel -DisableQuiesce:(!$EnableQuiescence) -AutoDelete $Retention -EncryptionKey $EncryptionKey -RunAsync:($EnableAsync)
      }
      
      Else 
      {
        $ZIPSession = Start-VBRZip -Entity $VM -Folder $Directory -Compression $CompressionLevel -DisableQuiesce:(!$EnableQuiescence) -AutoDelete $Retention -RunAsync:($EnableAsync)
      }
    

  }

}
#Write-Host "Done."
Exit
