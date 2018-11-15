Import-Module ActiveDirectory
Add-PSSNapin -Name Microsoft.Exchange.Management.PowerShell.E2010

#Organization specific properties
$SourceDomain = "Contoso"

#Read domain controller info.
$DestinationDomainPDC = (Get-ADDomain | Select-Object PDCEmulator).PDCEmulator
$SourceDomainPDC = (Get-ADDomain -Identity $SourceDomain | Select-Object PDCEmulator).PDCEmulator

#Read in CSV file
$inputFile = Read-Host "Please enter the file name you had used in S1 (EG; test.csv)"
$csvInfo = Import-CSV -Delimiter "," -Path ("C:\Scripts\Exchange Migration\CSVs\out\" + $inputFile)

#Grab local and remote credentials.
$local = Get-Credential -Message "Please enter your destination domain credentials"
$remote = Get-Credential -Message "Please enter your source domain credentials"

Write-Host "Preparing move requests..."

#Prepare move requests.
cd "D:\Program Files\Microsoft\Exchange Server\V15\Scripts"
ForEach($user in $csvInfo)
{
    Write-Host "Preparing Move Request for "$user.SamAccountName
    .\Prepare-MoveRequest.ps1 -Identity $user.SamAccountName -RemoteForestDomainController $SourceDomainPDC -RemoteForestCredential $remote -LocalForestDomainController $DestinationDomainPDC -LocalForestCredential $local -Verbose -UseLocalObject -OverwriteLocalObject
}
Write-Host "Script Completed @ " (Get-Date) " Please allow for replication"