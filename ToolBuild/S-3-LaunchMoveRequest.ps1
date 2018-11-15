Import-Module ActiveDirectory
Add-PSSNapin -Name Microsoft.Exchange.Management.PowerShell.E2010

#Organization specific properties
$TargetDeliveryDomain = 'contoso.mail.onmicrosoft.com'
$RemoteHostName = 'hybrid.contoso.com'
$TargetDatabase = 'migrationin'

#Read domain controller info.
$DestinationDomainPDC = (Get-ADDomain | Select-Object PDCEmulator).PDCEmulator
$SourceDomainPDC = (Get-ADDomain -Identity "Contoso" | Select-Object PDCEmulator).PDCEmulator

#Read in CSV file
$inputFile = Read-Host "Please enter the file name you had used in S1 and S2 (EG; test.csv)"
$csvInfo = Import-CSV -Delimiter "," -Path ("C:\Scripts\Exchange Migration\CSVs\out\" + $inputFile)

#Grab source domain credentials.
$remote = Get-Credential -Message "Please enter your source domain credentials"

#Launch exchange move requests.
ForEach($user in $csvInfo)
{
    New-MoveRequest -Identity $user.SamAccountName -RemoteCredential $remote -DomainController $DestinationDomainPDC -TargetDeliveryDomain $TargetDeliveryDomain -Remote -RemoteHostName $RemoteHostName -TargetDatabase $TargetDatabase #-CompleteAfter '18:00'
}

Write-Host "Please Wait... Waiting for move requests to be registered."

Start-Sleep -Seconds 60

#Periodic update check
Write-Host "Periodic move request check..."
while($TRUE)
{
    Write-Host "******* Move Info *******"
    ForEach($user in $csvInfo)
    {
        Write-Host "Move request info for "$User.SamAccountName
        Get-MoveRequestStatistics -Identity $User.SamAccountName | fl displayname, identity, percentcomplete, status, statusdetail
    }
    Start-Sleep -Seconds (60*5) # Reports every 5 minutes.
}