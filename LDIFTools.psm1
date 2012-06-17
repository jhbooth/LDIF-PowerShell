#===============================================================================
function Send-LDIF
{
    [CmdletBinding()]
    param([parameter(Mandatory=$true)]$ldif, [string]$server = "localhost", [int]$port = 389, [string]$tag = "LDS")

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
Export-ModuleMember -Function Send-LDIF

Export-ModuleMember -Cmdlet Export-Ldif,Import-Ldif

