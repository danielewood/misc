$SourceWIM = "e:\combo.wim"
$DestESD = "e:\combo.esd"
$IndexCounts = dism /Get-WimInfo /wimfile:$SourceWIM
ForEach ($IndexCount in $IndexCounts) {
    If ($IndexCount -like "Index : *") {[int]$IndexTotal = $IndexCount.Replace('Index : ', '')}
}
$IndexTotal

for ($i = 1; $i -le $IndexTotal; $i++) {
    & dism /Export-Image /SourceImageFile:$SourceWIM /SourceIndex:$i /DestinationImageFile:$DestESD /Compress:recovery
} 
