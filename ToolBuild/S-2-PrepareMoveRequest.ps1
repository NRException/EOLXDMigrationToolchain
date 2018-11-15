#Requires -Version 3
#Requires -Modules Microsoft.Exchange.Management.PowerShell.E2010, ActiveDirectory

<#
    .SYNOPSIS
    Prepares the specified users for a mailbox migration.

    .DESCRIPTION
     Takes a CSV from the OUT directory and prepares the move requests
     Within the specified destination domain.

    .PARAMETER CSVFileName
    Specifies the OUT file name.

    .PARAMETER SourceDomain
    Specifies the destination domain that you're migrating your mailbox FROM.

    .PARAMETER DestinationDomain
    Specifies the destination domain that you're migrating your mailbox TO.

    .PARAMETER SourceDomainCredential
    A set of administrator credentials for the domain that you're migrating FROM

    .PARAMETER DestinationDomainCredential
    A set of administrator credentials for the domain that you're migrating TO

    .EXAMPLE

    C:\PS> S-2-PrepareMoveRequest.ps1 -CSVFileName accounts.csv -DestinationDomain 'accounting.contoso.local' -SourceDomainCredential (Get-Credential) -DestinationDomainCredential (Get-Credential)
#>

#region Bootstrapping

[CmdletBinding()]

Param(
    [Parameter(Mandatory=$TRUE,
               HelpMessage="The file name of the CSV inside the 'out' directory")]
    [String]$CSVFileName,
    [Parameter(Mandatory=$TRUE,
               HelpMessage="The FQDN of the domain that you're migrating your mailbox FROM")]
    [String]$SourceDomain,
    [Parameter(Mandatory=$TRUE,
               HelpMessage="The FQDN of the domain that you're migrating your mailbox TO")]
    [String]$DestinationDomain,
    [Parameter(Mandatory=$TRUE,
               HelpMessage="A set of administrator credentials for the domain that you're migrating FROM")]
    [PSCredential]$SourceDomainCredential,
    [Parameter(Mandatory=$TRUE,
               HelpMessage="A set of administrator credentials for the domain that you're migrating TO")]
    [PSCredential]$DestinationDomainCredential
)

Import-Module ActiveDirectory
Add-PSSNapin -Name Microsoft.Exchange.Management.PowerShell.E2010

#endregion

#Read domain controller info.
try {
    $DestinationDomainPDC = (Get-ADDomain -Identity $DestinationDomain -ErrorAction Stop -ErrorVariable $EV).PDCEmulator
    $SourceDomainPDC = (Get-ADDomain -Identity $SourceDomain -ErrorAction Stop -ErrorVariable $EV).PDCEmulator
} catch {
    Write-Error "Failed to find domain. Further information: $EV"
}

#Read in CSV file
try {
    $CSVFilePath = "C:\Scripts\Exchange Migration\CSVs\out\" + $CSVFileName
    $Data = Import-Csv -Delimiter "," $CSVFilePath -ErrorAction Stop -ErrorVariable $EV
} catch {
    Write-Error "Could not read CSV: $CSVFilePath. Further information: $EV"
}

#Prepare move requests.
cd "D:\Program Files\Microsoft\Exchange Server\V15\Scripts"
Write-Verbose "Preparing move requests..."
ForEach($user in $Data) {
    Write-Verbose "Preparing Move Request for $user.SamAccountName"

    try{
        $Output = .\Prepare-MoveRequest.ps1 `
            -Identity $user.SamAccountName `
            -RemoteForestDomainController $SourceDomainPDC `
            -RemoteForestCredential $SourceDomainCredential `
            -LocalForestDomainController $DestinationDomainPDC `
            -LocalForestCredential $DestinationDomainCredential `
            -Verbose `
            -UseLocalObject `
            -OverwriteLocalObject `
            -ErrorAction Stop `
            -ErrorVariable $EV
        Write-Output $Output
    } catch {
        Write-Error "Unable to prepare move request. Further information: $EV"
    }
}
Write-Verbose "Script Completed @ " (Get-Date) " Please allow for replication"