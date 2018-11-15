if($UserCredential -eq $null) {
$UserCredential = Get-Credential
} else {Write-Host "Credentials already entered..."}
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking

#Read in CSV file
$inputFile = Read-Host "Please enter the file name you had used in S1 (EG; test.csv)"
$csvInfo = Import-CSV -Delimiter "," -Path ("C:\Scripts\Exchange Migration\o365\CSVs\CalendarPermissions\" + $inputFile)

ForEach($object in $csvInfo)
{
   Write-Host ($object.UserToAdd + " To " + $object.TargetAddress + " With " + $object.PermissionClass)
   Add-MailboxFolderPermission -Identity ($object.TargetAddress + ":\calendar") -User $object.UserToAdd -AccessRights $object.PermissionClass
}