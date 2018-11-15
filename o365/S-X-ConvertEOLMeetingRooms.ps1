#Converts all users in an OUT CSV to a room mailbox in office 365.

Import-Module ActiveDirectory

#Read in CSV file
$inputFile = Read-Host "Please enter the file name you had used in S1 and S2 (EG; test.csv)"
$csvInfo = Import-CSV -Delimiter "," -Path ("C:\Scripts\Exchange Migration\CSVs\out\" + $inputFile)

$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

Import-PSSession $Session -DisableNameChecking

ForEach($user in $csvInfo)
{
    Set-Mailbox -Identity $User.EmailAddress -Type Room
}

Register-EngineEvent PowerShell.Exiting –Action { Remove-PSSession $Session }