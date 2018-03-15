[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

do {
  $Pos = [System.Windows.Forms.Cursor]::Position
  [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point((($Pos.X) + 1) , $Pos.Y)
  [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($Pos.X, $Pos.Y)
  (Get-Date -Format "HH:MM:ss - yyyyMMdd")
  Start-Sleep 30
 } until ($False)

 
