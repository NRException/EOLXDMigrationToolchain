#Connect to MSOnline.
if($UserCredential -eq $null) {
$UserCredential = Get-Credential
} else {Write-Host "Credentials already entered..."}
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking

$pAddress = Read-Host -Prompt "Please input proxy address to match against."
$uName = $pAddress.Split("@")[0]

#Get-Recipient | Where {[string] $str = ($_.EmailAddresses); $str.tolower().Contains($paddress.tolower()) -eq $true} | foreach {get-MsolUser -ObjectID $_.ExternalDirectoryObjectId | Where {($_.LastDirSyncTime -eq $null)}}

if($eolRecipients -eq $null){
Write-Host "Getting all MSOnline recipients. This might take a while..."
$eolRecipients = Get-Recipient -ResultSize Unlimited
} else {Write-Host "MSOL addresses already pulled..."}

Write-Host "Searching ProxyAddresses ("($eolRecipients.Count)") Found...`n"
ForEach ($user in $eolRecipients)
{
    $upnRegex_ThreeChar = "\b\w*"+$uName.Substring(0,3)+"\w*\b" #Could be found in x4/500 addresses.
    $upnRegex_FullQual = "\b\w*"+$pAddress+"\w*\b" #Could be found as a conflicting SMTP address.
    if($user.EmailAddresses -match $upnRegex_ThreeChar) {Write-Host "`nPossible partial match found on EmailAddress:"$user.EmailAddresses"|| UPN:"$user.Alias "`n" -ForegroundColor Yellow}
    if($user.EmailAddresses -match $upnRegex_FullQual) {Write-Host "`nPossible full match found on EmailAddress:"$user.EmailAddresses"|| UPN:"$user.Alias "`n" -ForegroundColor Yellow}
}

Register-EngineEvent PowerShell.Exiting –Action { Remove-PSSession $Session }