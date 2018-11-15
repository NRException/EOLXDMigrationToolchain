#Requires -Version 5.1

Import-Module MSOnline

$inputFile = Read-Host "Please enter the file name you had used in S1 (EG; test.csv)"
$csvInfo = Import-CSV -Delimiter "," -Path ("C:\Scripts\Exchange Migration\CSVs\out\" + $inputFile)
$msCred = Get-Credential -Message "Please enter your O365 credentials here."

if($msCred -ne $null)
{
    #Bootstrap our connection to o365.
    Connect-MsolService -Credential $msCred

    #User CSV loop.
    ForEach($User in $csvInfo)
    {
        Write-Host "Attempting Zone Allocation for" $User.UserPrincipalName

        #Set user country code.
        Set-MsolUser -UserPrincipalName $User.UserPrincipalName -UsageLocation GB

        #Validate and move on.
        if( (Get-MsolUser -UserPrincipalName $User.UserPrincipalName | select UsageLocation).UsageLocation -eq "GB" )
        {
            Write-Host "OK - UsageLocation=GB`n`tContinuing..." -ForegroundColor Green

            #Set user license.
            Set-MsolUserLicense -UserPrincipalName $User.UserPrincipalName -AddLicenses "reseller-account:EXCHANGESTANDARD"

            #Validate and move on.
            $Licenses = Get-MsolUser -UserPrincipalName $User.UserPrincipalName | select Licenses
            ForEach ($lic in $Licenses) {if($lic.Licenses.AccountSkuId -eq "reseller-account:EXCHANGESTANDARD")
            {
                Write-Host "`t`tUser License applied for" $User.UserPrincipalName".Continuing..." -ForegroundColor Green
                break
            }}

        } else
        {Write-Host "FAIL - UsageLocation not set correctly. License has not been applied." -ForegroundColor Red}
    }
}