Import-Module ActiveDirectory
Add-PSSNapin -Name Microsoft.Exchange.Management.PowerShell.E2010

#Read in CSV file
$inputFile = Read-Host "Please enter the file name you had used in S1 (EG; test.csv)"
$csvInfo = Import-CSV -Delimiter "," -Path ("C:\Scripts\Exchange Migration\CSVs\out\" + $inputFile)

$ConsoleOut = [PSCustomObject]@()
ForEach($user in $csvInfo)
{
    Write-Host "Move request info for "$User.SamAccountName
    Get-MoveRequestStatistics -Identity $User.SamAccountName | ft displayname, percentcomplete, status, statusdetail
}
