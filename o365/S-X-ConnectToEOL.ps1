if($UserCredential -eq $null) {
$UserCredential = Get-Credential
} else {Write-Host "Credentials already entered..."}

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking