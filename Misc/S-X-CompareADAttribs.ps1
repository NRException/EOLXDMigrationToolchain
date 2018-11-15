# Home; Active Directory; Attributes; Users; Analysis;
 
# Requires PowerShell 3 due to how the type accelerator I use to generate custom objects
#requires -version 3
# Also requires that the module "ActiveDirectory" is loaded to use Get-ADUser
 
# Required to load the Messagebox to display a friendly error if no user is found
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
 
Function Get-UserInput([string]$Description)
{
    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = "AD User Attributes"
    $objForm.Size = New-Object System.Drawing.Size(300,170) 
    $objForm.StartPosition = "CenterScreen"
 
    $objForm.KeyPreview = $True
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
        {$x=$objTextBox.Text;$objForm.Close()}})
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
        {$objForm.Close()}})
 
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(75,95)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"
    $OKButton.Add_Click({$x=$objTextBox.Text;$objForm.Close()})
    $objForm.Controls.Add($OKButton)
 
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(150,95)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click({$objTextBox.text = "Cancel"; $objForm.Close()})
    $objForm.Controls.Add($CancelButton)
 
    $objLabel = New-Object System.Windows.Forms.Label
    $objLabel.Location = New-Object System.Drawing.Size(10,20) 
    $objLabel.Size = New-Object System.Drawing.Size(280,40) 
    $objLabel.Text = $Description
    $objForm.Controls.Add($objLabel) 
 
    $objTextBox = New-Object System.Windows.Forms.TextBox 
    $objTextBox.Location = New-Object System.Drawing.Size(10,60) 
    $objTextBox.Size = New-Object System.Drawing.Size(260,20)
    # Include default usernames here if desired
    $objTextBox.Text = "samaccountname" 
    $objForm.Controls.Add($objTextBox) 
 
    $objForm.Topmost = $True
 
    $objForm.Add_Shown({$objForm.Activate(); $objTextBox.focus()})
    [void] $objForm.ShowDialog()
 
    return $objtextBox.Text
}
 
# Create a custom object that will store the values we discover to present them in a gridview
$C="UserName Attribute Value"; $myobj=@(); Function Add-ToObject{$args|%{$i++;$P+=@{$C.split(" ")[$i-1]=$_}};$Script:myObj+=@([pscustomobject]$P)}
 
$UserNames = Get-UserInput "Enter samaccountname(s) to show AD user attributes (Separate each name with a <code>";</code>")"
if($UserNames -eq "Cancel" -or $UserNames -eq '') { break } 
# If more than one user is found, split them out into separate elements so they can be checked one at a time
$UserNames = $UserNames -split ";"
 
# This code can probably be combined with the other checks as we are performing multiple redundant get-aduser calls but this works for now
# The purpose of this loop is simply to validate that the users exist and if not, display an error message, and quit
ForEach($Username in $UserNames)
{
    try{
        Get-ADUser -Identity $UserName -ErrorAction SilentlyContinue | Out-Null
    }
    catch{
        [Windows.Forms.MessageBox]::Show("Cannot find user <code>'$Username</code>'.  `nExiting Tool." , "AD User Attributes", [Windows.Forms.MessageBoxButtons]::OK , [Windows.Forms.MessageBoxIcon]::Error) | Out-Null; Exit
    }
}
cls
 
# We need to enumerate all Active Directory propeties so we can later expand each of them and store any entries with multiple line or objects as a single text string
# Different users can have different attributes so we need to first build a list of all possible attributes to later iterate through
$UserNames | % { Write-Progress -Activity "Reading active directory attributes for $UserName..."; $Props += (Get-ADUser $_ -Properties * | Get-Member -MemberType Properties)  }
 
# Once we have a master list of all properties, generate a list of all of the unique ones, eliminating the duplicates
$Props = $Props | select -Unique
 
ForEach($Username in $UserNames) 
{
    # Grab all attributes and values from Active Directory for this user
    $UserDetails = get-aduser $UserName -Properties * -ErrorAction Stop
 
    ForEach ($UserDetail in $UserDetails)
    {
        ForEach($Prop in $Props)
        {
            Write-Progress -Activity "Reading active directory attributes for $UserName..." -Status $Prop
             
            # For properties with multiple values, expand them and append them to a single line separated by a semicolon so Out-GridView can search it
            $Result = (get-aduser $UserName -Properties * | select -ExpandProperty $Prop.Name) -join ";"
             
            # The attributes defined below are known to be stored in a unique format.  We need to confirm them to a human readable form using the .NET method ::Fromfiletime
            switch ($Prop.name) {
                'lastLogonDate' { if(!$Result) { $Result = "Never Logged In" } }
 
                { 
                    'lastLogonTimestamp',
                    'lastLogon',
                    'badPasswordTime',
                    'lastLogonTimestamp',
                    'pwdlastset' -contains $_ } { if($Result) { $Result = [string][datetime]::fromfiletime($Result) } 
                }
                # If a password is marked to never expire, it is assigned the value below.  if we find that, we translate that into human readable form.  Otherwise we convert it
                'accountExpires' { if ($Result -eq "9223372036854775807") {$Result = "Never Expires" } Else { $Result = [string][datetime]::fromfiletime($Result) } }
            }
             
            Add-ToObject $UserName $Prop.Name $Result
        }
    }
}

# Whatever is selected inside the grid view is automatically exported to the clipboard as CSV data
$SendToClipboard = $myobj | select UserName, Attribute, Value | Out-GridView -Title "Active Directory User Attributes" -PassThru | ConvertTo-CSV -NoTypeInformation | clip