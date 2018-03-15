# Sennheiser web store never has parts in stock, this script checks if parts are in stock and sends an email if they are. 
# Use with Task Scheduler running as a background task.

$SMTPEmail = 'bot@contoso.com'
$SMTPpwd = 'pass'
$EmailTo = 'me@contoso.com'
$SMSAddress = '1112223333@txt.att.net'
$LogFile = "C:\Users\Public\Check-Sennheiser-Status.log"
$StatusFile = "C:\Users\Public\Check-Sennheiser-Status.txt"

Stop-transcript
Start-transcript -Path $LogFile

If (!(Test-Path -Path "$StatusFile")){
	New-Item -ItemType File "$StatusFile"
}
$URLs = 'https://en-us.sennheiser.com/accessories--unp-console-cable--game-one--game-zero', 'https://en-us.sennheiser.com/accessories--pc-360--pc-363d--ear-cushion-hzp-26', 'https://en-us.sennheiser.com/gaming-headset-pc-373d'


foreach ($URL in $URLs){
    $SennStatus=$null
    $SennStatus = Get-Content -Path $StatusFile | Where-Object { $_.Contains("$(Get-Date -Format yyyyMMdd) - $URL") }
    #Check if we have already alerted for this product today, if so, skip loop
    If ($SennStatus){continue}
    
    $Page = Invoke-WebRequest -Uri $URL -UseBasicParsing

    $Title = ($Page.RawContent -split "<title>")[1]
    $Title = ($Title -split "-")[0]
    Write-Output "Title: $Title"

    $ItemStatus = $null
    $ItemStatus = ($Page.RawContent -split "product-stage__price__text'>")[1]
    $ItemStatus = ($ItemStatus -split '</div>')[0]
    Write-Output "Item Status: $ItemStatus"
    If ($ItemStatus -eq "OUT OF STOCK"){continue}
    If (!$Title){continue}
    
    "$(Get-Date -Format yyyyMMdd) - $URL" | Add-Content -Path $StatusFile

    $securepwd = ConvertTo-SecureString $SMTPpwd -AsPlainText -Force    
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SMTPEmail, $securepwd    
    $Body = (("<h1 " + ($($Page.RawContent) -split '<h1 ')[1] ) -split "</svg>")[0] + "</svg>"
    $Body = $Body -replace 'href="/', 'href="https://en-us.sennheiser.com/'

    $param = @{
        Body = $Body
        BodyAsHtml = $True
        From = $SMTPEmail
        To = $EmailTo
        SmtpServer = 'smtp.gmail.com'
        UseSsl = $True
        Port = 587
        Subject = "$Title in stock"
        Credential = $cred
    }

    Send-MailMessage @param
    $param.To = $SMSAddress
    $param.Body = $URL
    $param.BodyAsHtml = $False
    Send-MailMessage @param
    # 506507
    # https://en-us.sennheiser.com/accessories--unp-console-cable--game-one--game-zero
}

