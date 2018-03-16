#
# Title:    Set-AccountPictureFromAD.ps1
# Author:    Jourdan Templeton
# Email:    hello@jourdant.me
# Modified:    12/06/2014 3:27PM NZDT
#

[CmdletBinding(SupportsShouldProcess=$true)]Param()
function Test-Null($InputObject) { return !([bool]$InputObject) }

#get sid and photo for current user
$user = ([ADSISearcher]"(&(objectCategory=User)(SAMAccountName=$env:username))").FindOne().Properties
$user_photo = $user.thumbnailphoto
$user_sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
Write-Verbose "Updating account picture for $($user.displayname)..."

#continue if an image was returned
If ((Test-Null $user_photo) -eq $false)  
{
    Write-Verbose "Success. Photo exists in Active Directory."

    #set up image sizes and base path
    $image_sizes = @(40, 96, 200, 240, 448)
    $image_mask = "Image{0}.jpg"
    $image_base = $env:public + "\AccountPictures"

    #set up registry
    $reg_base = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\{0}"
    $reg_key = [string]::format($reg_base, $user_sid)
    $reg_value_mask = "Image{0}"
    If ((Test-Path -Path $reg_key) -eq $false) { New-Item -Path $reg_key } 

    #save images, set reg keys
    ForEach ($size in $image_sizes)
    {
        #create hidden directory, if it doesn't exist
        $dir = $image_base + "\" + $user_sid
        If ((Test-Path -Path $dir) -eq $false) { $(mkdir $dir).Attributes = "Hidden" }

        #save photo to disk, overwrite existing files
        $file_name = ([string]::format($image_mask, $size))
        $path = $dir + "\" + $file_name
        Write-Verbose "  saving: $file_name"
        $user_photo | Set-Content -Path $path -Encoding Byte -Force

        #save the path in registry, overwrite existing entries
        $name = [string]::format($reg_value_mask, $size)
        $value = New-ItemProperty -Path $reg_key -Name $name -Value $path -Force
    }

    Write-Verbose "Done."
} else { Write-Error "No photo found in Active Directory for $env:username" }