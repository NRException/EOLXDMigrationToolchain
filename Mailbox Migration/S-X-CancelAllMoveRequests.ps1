#Read in CSV file
$inputFile = Read-Host "Please enter the file name you had used in S1 and S2 (EG; test.csv)"
$csvInfo = Import-CSV -Delimiter "," -Path ("C:\Scripts\Exchange Migration\CSVs\out\" + $inputFile)

#Launch exchange move requests.
ForEach($user in $csvInfo)
{
    Remove-MoveRequest -Identity $user.SamAccountName
}

