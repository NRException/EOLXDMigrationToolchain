Import-Module ActiveDirectory
Add-PSSNapin -Name Microsoft.Exchange.Management.PowerShell.E2010

#Read domain controller info.
$DestinationDomainPDC = (Get-ADDomain | Select-Object PDCEmulator).PDCEmulator

#Read preliminary info.
$Input = read-host "Please enter the filename of exported CSV (Example: test.csv)"
$Filename = "C:\Scripts\Exchange Migration\CSVs\in\" + $Input
$Data = Import-Csv -Delimiter "," $Filename

#Grab user info from AD.
$UserArray = @()
ForEach($object in $Data.Name)
{ 
    $UserObj = Get-ADUser -Filter {Name -eq $object} -Properties SamAccountName,EmailAddress -Server $DestinationDomainPDC
    if($UserObj -eq $NULL) {Write-Host "Could not find "$object "in destination domain Skipping..." -ForegroundColor Red}
    $UserArray += $UserObj
}

#Export that info to a CSV.
$UserArray | Export-Csv -Path ("C:\Scripts\Exchange Migration\CSVs\out\" + $Input)

#Mail Enable those users.
ForEach ($UserObject in $UserArray) {
    Write-Host "Mail enabling " $UserObject.SamAccountName
    Enable-MailUser $UserObject.SamAccountName -DomainController $DestinationDomainPDC -ExternalEmailAddress $UserObject.EmailAddress
}
Write-Host "Script Completed @ " (Get-Date) " Please allow for replication"