#===============================================================================

<#
 .Synopsis
  Imports directory credentials from a file, and returns a custom PowerShell object.

 .Description
  Imports directory credentials from a file created using Export-DirectoryCredential.

 .Parameter Path
  Path to the file containing credentials

 .Example
   # Import from the default DirectoryCredential.xml file
   Import-DirectoryCredential

 .Example
   # Import directory credentials from file called TestUser.xml
   Import-DirectoryCredential '.\TestUser.xml'
#>
function Import-DirectoryCredential
{
    [CmdletBinding()]
    param ($Path = "DirectoryCredential.xml")

    # Import credential file
    $import = Import-Clixml $Path

    # Test for valid import
    if ($import.PSObject.TypeNames -notcontains 'Deserialized.ExportedDirectoryCredential')
    {
        Throw "Input is not a valid ExportedDirectoryCredential object, exiting."
    }

    Add-Member -InputObject $import -MemberType AliasProperty -Name DN -Value DistinguishedName
    Add-Member -InputObject $import -MemberType AliasProperty -Name ID -Value UserID
    Add-Member -InputObject $import -MemberType ScriptMethod -Name Password -Value { ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((ConvertTo-SecureString $this.EncryptedPassword)))) }

    Write-Output $import
}
#===============================================================================

<#
 .Synopsis
  Exports directory credentials to a file

 .Description
  Exports directory credentials to a file, by creating a custom PowerShell object and exporting it.

 .Parameter Path
  Path to the file containing credentials

 .Example
   # Export to the default DirectoryCredential.xml file
   Export-DirectoryCredential

 .Example
   # Export directory credentials to a file called TestUser.xml
   Export-DirectoryCredential '.\TestUser.xml'
#>
function Export-DirectoryCredential
{
    param ($Path = "DirectoryCredential.xml")

    # Create temporary object to be serialized to disk
    $export = New-Object System.Management.Automation.PSObject

    # Give object a type name which can be identified later
    $export.PSObject.TypeNames.Insert(0, ’ExportedDirectoryCredential’)

    $uid = Read-Host -Prompt "Enter user name"
    $dmn = Read-Host -Prompt 'Enter domain'
    $dn = Read-Host -Prompt 'Enter DN'
    $pw = Read-Host -Prompt 'Enter password' -AsSecureString

    Add-Member -InputObject $export -MemberType NoteProperty -Name UserID -Value $uid

    Add-Member -InputObject $export -MemberType NoteProperty -Name Domain -Value $dmn

    Add-Member -InputObject $export -MemberType NoteProperty -Name DistinguishedName -Value $dn

    if ($pw.Length -gt 0)
    {
        Add-Member -InputObject $export -MemberType NoteProperty -Name EncryptedPassword -Value (ConvertFrom-SecureString $pw)
    }

    $export | Export-Clixml $Path

    # Return FileInfo object referring to saved credentials
    Get-Item $Path
}

#===============================================================================

function Send-LDIF
{
    [CmdletBinding()]
    param ([parameter(Mandatory = $true)]$ldif, [string]$server = "localhost", [int]$port = 389, [string]$tag = "LDS")

    # Get the credentials we need to do the search
    $credentialFile = ('{0}\{1}-{2}-{3}.xml' -f $HOME, $env:USERNAME, $env:COMPUTERNAME, $tag)
    Write-Verbose "Getting credentials from $credentialFile"

    if (Test-Path $credentialFile)
    {
        $creds = Import-DirectoryCredential $credentialFile
        $ldifde = Get-Command ldifde.exe -erroraction silentlycontinue

        if ($creds -and $ldifde)
        {
            ldifde.exe -i -f $ldif -s $server -t $port -c "DC=X" "#configurationNamingContext" -b $creds.ID $creds.Domain $creds.Password() -k -j .
        }
    }
    else
    {
        Write-Error "No credentials ($credentialFile missing)"
        return
    }

}

#===============================================================================

function New-DirectoryCredentialXml
{
    [CmdletBinding()]
    param ([parameter(Mandatory = $true)]$tag)

    $credFile = '{0}\{1}_{2}_{3}.xml' -f $HOME, $env:USERNAME, $env:COMPUTERNAME, $tag

    Export-DirectoryCredential $credFile
}
Export-ModuleMember -Function New-DirectoryCredentialXml

#===============================================================================

function Convert-EscapeDnComponent
{
    [CmdletBinding()]
    param ([parameter(Mandatory = $true)][string]$token)

    $result = ($token -replace '(?<!\\)[+;,#<>"=]', '\$&')

    $result
}

Export-ModuleMember -Function Convert-EscapeDnComponent

#===============================================================================

Export-ModuleMember -Cmdlet Export-Ldif, Import-Ldif

#===============================================================================
