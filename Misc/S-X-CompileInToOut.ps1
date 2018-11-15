Import-Module ActiveDirectory
Add-PSSNapin -Name Microsoft.Exchange.Management.PowerShell.E2010

#Read preliminary info.
$Input = read-host "Please enter the filename of exported CSV (Example: test.csv)"
$Filename = "C:\Scripts\Exchange Migration\CSVs\in\" + $Input
$Data = Import-Csv -Delimiter "," $Filename

#Grab user info from AD.
$UserArray = @()
ForEach($object in $Data.Name)
{ 
    $UserObj = Get-ADUser -Filter {Name -eq $object} -Properties SamAccountName,EmailAddress
    $UserArray += $UserObj
}

#Export that info to a CSV.
$UserArray | Export-Csv -Path ("C:\Scripts\Exchange Migration\CSVs\out\" + $Input)