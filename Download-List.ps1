$links='
'

$results=@(); foreach ($link in $links.Split("`r`n")){
	$results+= $link
}
$results=$results | sort -u

foreach ($result in $results){
	$request = [System.Net.WebRequest]::Create($result)
	$request.AllowAutoRedirect=$false
	$response = $request.GetResponse()
	Invoke-WebRequest "$result" -Outfile $([System.IO.Path]::GetFileName($($response.GetResponseHeader("Content-Disposition").Split('=')[1])))
}
