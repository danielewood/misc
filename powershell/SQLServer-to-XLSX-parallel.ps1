Start-Transcript -Force -IncludeInvocationHeader -Verbose E:\MSSQL-Jobs\Logs\ReportsByAccount-CompleteHistory.log

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
# Do not import SQLPS when running as a SQLPS Job, but you must import it if running standalone
#Import-Module SQLPS -DisableNameChecking -Force
Import-Module ImportExcel -Force
Set-Location "C:\"

#Clean Up Target Folder
Get-ChildItem 'E:\MSSQL-Jobs\Reports\ReportsByAccount\CompleteHistory\' | Where { ! $_.PSIsContainer } | Remove-Item -Force -ErrorAction SilentlyContinue

workflow Reports-CompleteHistory
{
$BaseFilePath='E:\MSSQL-Jobs\Reports\ReportsByAccount\CompleteHistory\'

$CompanyQuery = "SELECT [CompanyID],[CompanyName] FROM [DB_NAME].[dbo].[company]"
$Companies=Invoke-Sqlcmd -Query "$CompanyQuery" -ServerInstance localhost

ForEach -ThrottleLimit 20 -Parallel ($Company in $Companies){
    $CompanyName=$Company.CompanyName
    $CompanyID=$Company.CompanyID

    $ReportQuery = @"
                    SELECT [SHIPPER/REPORTING CO]
                          ,[SHIPMENT TYPE]
                          ,[SHIPPED TO]
                          ,[RECEIVED FROM]
                          ,[ShippedVia]
                          ,[FinalCompany]
                          ,[BrandName]
                          ,[ModelName]
                          ,[ChipModel]
                          ,[CountryName]
                          ,[TerritoryName]
                          ,[RegionName]
                          ,[UNITS]
                          ,[ContractID]
                          ,[MonthYear]
                          ,[QuarterYear]
                          ,[Version]
                      FROM [DB_NAME].[dbo].[Reporting_view]
                      WHERE $CompanyID IN (ShipToID, CompanyID, SupplierID)
                      ORDER BY QuarterYear DESC, MonthYear DESC 
"@
    $Reports=Invoke-Sqlcmd -Query $ReportQuery -ServerInstance localhost

    If ([bool]$Reports){
        $CompanyFileName=$CompanyName -replace "\W","_"
        $OutputFile="$BaseFilePath$CompanyFileName.xlsx"

        #Format the data as a nice Table
        InlineScript {
            Write-Output "Writing file $using:OutputFile"; $using:Reports | Select-Object -Property * -ExcludeProperty PSComputerName,PSShowComputerName,PSSourceJobInstanceId |
            Export-Excel -Path "$using:OutputFile" -AutoSize -StartRow 1 -WorkSheetname "Sheet1"  -TableName "Table"
        }  
        
    }
}

}
$ErrorActionPreference='Stop'
Reports-CompleteHistory

Stop-Transcript 
