#Requires -Version 3
#Requires -Modules Microsoft.Exchange.Management.PowerShell.E2010, ActiveDirectory

<#
    .SYNOPSIS
    Mail enables a batch of users in the specified destination domain.

    .DESCRIPTION
    Takes a CSV file name within the "IN" folder
    And batch mail enables their user in the destination domain.

    .PARAMETER CSVFileName
    Specifies the IN file name.

    .PARAMETER DestinationDomain
    Specifies the destination domain that you're migrating your mailbox to.

    .EXAMPLE

    C:\PS> S-1-MailEnable.ps1 -CSVFileName accounts.csv -DestinationDomain 'accounting.contoso.local'
#>

#region Bootstrapping

[CmdletBinding()]

Param(
    [Parameter(Mandatory=$TRUE,
               HelpMessage="The file name of the CSV inside the 'in' directory")]
    [String]$CSVFileName,
    [Parameter(Mandatory=$TRUE,
               HelpMessage="The FQDN of the domain that you're migrating your mailbox TO")]
    [String]$DestinationDomain
)

Import-Module ActiveDirectory
Add-PSSNapin -Name Microsoft.Exchange.Management.PowerShell.E2010

#endregion


#Get PDC Emulator of current domain
try{
    $DestinationDomainPDC = (Get-ADDomain -Identity $DestinationDomain | Select-Object PDCEmulator -ErrorAction Stop -ErrorVariable $EV).PDCEmulator
} catch {
    Write-Error "Failed to find domain. Further information: $EV"
}

#Read CSV Provided by param.
try {
    $CSVFilePath = "C:\Scripts\Exchange Migration\CSVs\in\" + $CSVFileName
    $Data = Import-Csv -Delimiter "," $CSVFilePath -ErrorAction Stop -ErrorVariable $EV
} catch {
    Write-Error "Could not read CSV: $CSVFilePath. Further information: $EV"
}

#Grab user info from AD.
$UserArray = @()
ForEach($DisplayName in $Data.Name) { 
    try{
        $UserObj = Get-ADUser -Filter {Name -eq $DisplayName} -Properties SamAccountName,EmailAddress -Server $DestinationDomainPDC -ErrorAction Stop
        $UserArray += $UserObj
    } catch {
        Write-Verbose "Could not find user $DisplayName. Did you spell their name correctly in the CSV?"
    }
}

#Export that info to a CSV.
try {
    $OutPath = ("C:\Scripts\Exchange Migration\CSVs\out\" + $Input)
    $UserArray | Export-Csv -Path $OutPath -ErrorAction Stop -ErrorVariable $EV
} catch {
    Write-Error "Could not write OUT CSV: $OutPath. Further information: $EV"
}

#Mail Enable those users.
ForEach ($UserObject in $UserArray) {
    Write-Verbose "Mail enabling $UserObject.SamAccountName"
    try{
        $EnableInfo = Enable-MailUser $UserObject.SamAccountName -DomainController $DestinationDomainPDC -ExternalEmailAddress $UserObject.EmailAddress -ErrorAction Stop -ErrorVariable $EV
    } catch {
        Write-Error "Failed to MailEnable user $UserObject.SamAccountName. Further information: $EV" -Category NotEnabled
    } finally {
        Write-Output $EnableInfo
    }
}
Write-Verbose "Script Completed @ " (Get-Date) " Please allow for replication"