$IPj = Invoke-WebRequest http://api.ipify.org?format=json
$IP = (ConvertFrom-JSON $IPj).ip
$domain = 'contoso.com'
$type = 'SRV'
$alias = '@' # myalias.mydomain.com
$method = 'get'

$key = 'a'
$secret = 'a'

$JSON = ConvertTo-Json @{data = $IP; ttl = 3600}
# you can also use an array of values: @(@{data=$IP1;ttl=3600},@{data=$IP2;ttl=3600},etc...)

$headers = @{}
$headers["Authorization"] = 'sso-key ' + $key + ':' + $secret

try {
    if ($method -eq 'put') { 
        $ret = Invoke-WebRequest https://api.godaddy.com/v1/domains/$domain/records/$type/$alias  -method $method -headers $headers -Body $json -ContentType "application/json"
    }
    if ($method -eq 'get') { 
        $ret = Invoke-WebRequest https://api.godaddy.com/v1/domains/$domain/records/$type/$alias  -method $method -headers $headers -ContentType "application/json"
        #$ret = Invoke-WebRequest https://api.godaddy.com/v1/domains/$domain/records -method $method -headers $headers -ContentType "application/json"
    }
    if ($ret.StatusCode -eq 200) { Write-Host "Success!" -for yellow } else { Write-Host "ERROR" -for red }
}
catch {
    $result = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($result)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    $responseBody = $responseBody | ConvertFrom-Json | Format-Custom | Out-String
    Write-Host "ERROR: $responseBody" -for red
}

$RemoteDNS = $ret.Content | ConvertFrom-Json
$RemoteDNS = $RemoteDNS | Where-Object Name -notmatch "_"
$RemoteDNS

ForEach ($RemoteDNSLine in $($RemoteDNS )) {
    Write-Host "1 $($RemoteDNSLine.Name)"

}
