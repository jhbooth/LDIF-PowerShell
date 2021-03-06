﻿
function Validate-Path
{
	<#
		.SYNOPSIS
			Validates if path has valid characters

		.DESCRIPTION
			Validates if path has valid characters

		.PARAMETER  Path
			A string containing a directory or file path

		.INPUTS
			System.String

		.OUTPUTS
			System.Boolean
	#>
    [OutputType([Boolean])]
    param ([string]$Path)

    if ($Path -eq $null -or $Path -eq "")
    {
        return $false
    }

    $invalidChars = [System.IO.Path]::GetInvalidPathChars();

    foreach ($pathChar in $Path)
    {
        foreach ($invalid in $invalidChars)
        {
            if ($pathChar -eq $invalid)
            {
                return $false
            }
        }
    }

    return $true
}

<#
    .SYNOPSIS
        Reads LDIF data from an LDAP server and writes it to file.

    .DESCRIPTION
        Wraps command line tools to retrieve LDIF files from LDAP Servers; by default, uses ldifde.exe, but can also use laimex.exe from Softerra.

    .PARAMETER Path
        Path to an LDIF file to contain the output

    .PARAMETER Server
        Name of the server from which the LDIF will be read.

    .PARAMETER Port
        Port used to connect to LDAP server; default 389

    .PARAMETER SearchBase
        The root DN where the search will be run.

    .PARAMETER LdapFilter
        Search filter to use; default is (objectClass=*)

    .PARAMETER Scope
        Search scope - one of Base, OneLevel, or Subtree; default is Subtree

    .PARAMETER Credential
        A description of the Credential parameter.

    .PARAMETER Exclude
        A description of the Exclude parameter.

    .PARAMETER Include
        A description of the Include parameter.

    .EXAMPLE
        PS C:\> Read-Ldif -Path 'local.ldf' -Server 'localhost'

        'This is the output'
        This example shows how to call the Get-Ldif function with named parameters.

    .NOTES
        Additional information about the function or script.
#>
function Read-Ldif
{
    [CmdletBinding(DefaultParameterSetName='ldifde')]
    [OutputType([Boolean])]
    param
    (
        [ValidateNotNullOrEmpty()]
        [Alias('FilePath')]
        [Parameter(Mandatory = $true,ParameterSetName = 'ldifde')]
        [Parameter(ParameterSetName = 'laimex')]
        [string]
        $Path,

        [Parameter(ParameterSetName = 'ldifde')]
        [Parameter(ParameterSetName = 'laimex')]
        [string]
        $Server,

        [Parameter(ParameterSetName = 'ldifde')]
        [Parameter(ParameterSetName = 'laimex')]
        [int]
        $Port = 389,

        [Parameter(ParameterSetName = 'ldifde')]
        [Parameter(ParameterSetName = 'laimex')]
        [string]
        $SearchBase,

        [Parameter(ParameterSetName = 'ldifde')]
        [Parameter(ParameterSetName = 'laimex')]
        [Alias('Filter')]
        [string]
        $LdapFilter = '(objectClass=*)',

        [Parameter(ParameterSetName = 'ldifde')]
        [Parameter(ParameterSetName = 'laimex')]
        [ValidateSet('Base', 'OneLevel', 'Subtree')]
        [string]
        $Scope = 'Subtree',

        [Parameter(ParameterSetName = 'ldifde')]
        [Parameter(ParameterSetName = 'laimex')]
        [string[]]
        $Include,

        [Parameter(ParameterSetName = 'ldifde')]
        [string[]]
        $Exclude,

        [Parameter(ParameterSetName = 'ldifde')]
        [switch]
        $Ldifde = $true,

        [Parameter(ParameterSetName = 'laimex')]
        [switch]
        $Laimex,

        [Parameter(ParameterSetName = 'ldifde')]
        [Parameter(ParameterSetName = 'laimex')]
        [pscredential]
        $Credential
    )

    begin
    {
        $ldifArguments = @()

        if ($Laimex)
        {
            $cmd = (Get-Command laimex.exe -ErrorAction 'SilentlyContinue').Path
        }
        else
        {
            $cmd = (Get-Command ldifde.exe -ErrorAction 'SilentlyContinue').Path
        }

        if (!$cmd)
        {
            Write-Error "Can't find command line tool. Aborting" -ErrorAction 'Stop'
        }

        if (Validate-Path $Path)
        {
            $ldifArguments += '-f {0}' -f $Path
        }
        else
        {
            Write-Error "Invalid characters in path name" -ErrorAction 'Stop'
        }

        if ($PSBoundParameters.ContainsKey('Server'))
        {
            if ($Laimex)
            {
                $ldifArguments += '-s "{0}:{1}"' -f $Server, $Port
            }
            else
            {
                $ldifArguments += '-s {0}' -f $Server
            }
        }

        if ($PSBoundParameters.ContainsKey('Port'))
        {
            if (!$Laimex)
            {
                $ldifArguments += '-t {0}' -f $Port
            }
        }

        if ($PSBoundParameters.ContainsKey('SearchBase'))
        {
            if ($Laimex)
            {
                $ldifArguments += '-r "{0}"' -f $SearchBase
            }
            else
            {
                $ldifArguments += '-d "{0}"' -f $SearchBase
            }
        }

        if ($PSBoundParameters.ContainsKey('LdapFilter'))
        {
            if ($Laimex)
            {
                $ldifArguments += '-t "{0}"' -f $LdapFilter
            }
            else
            {
                $ldifArguments += '-r "{0}"' -f $LdapFilter
            }
        }

        if ($PSBoundParameters.ContainsKey('Scope'))
        {
            if ($Laimex)
            {
                switch ($Scope)
                {
                    'Base' { $scp = 'BASE' }
                    'OneLevel' { $scp = 'ONE' }
                    'Subtree' { $scp = 'SUB' }
                    default { $scp = 'SUB' }
                }
                $ldifArguments += '-p {0}' -f $scp
            }
            else
            {
                $ldifArguments += '-p {0}' -f $Scope
            }
        }
        else
        {
            if ($Laimex)
            {
                $ldifArguments += '-p SUB'
            }
        }

        if ($PSBoundParameters.ContainsKey('Include'))
        {
            if ($Laimex)
            {
                $ldifArguments += '-a "{0}"' -f ($Include -join ',')
            }
            else
            {
                $ldifArguments += '-l "{0}"' -f ($Include -join ',')
            }
        }

        if ($PSBoundParameters.ContainsKey('Exclude'))
        {
            if ($Laimex)
            {
                # $ldifArguments += '-xa "{0}"' -f ($Exclude -join ',')
            }
            else
            {
                $ldifArguments += '-o "{0}"' -f ($Exclude -join ',')
            }
        }

        if ($PSBoundParameters.ContainsKey('Credential'))
        {
            $password = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)))

            # UserName contains UPN
            if (($Credential.UserName -match '\A(?<account>[^}{#''~*+)(><!/\\=?` ]{1,64})@(?<domain>(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9]*[a-z0-9]))\Z'))
            {
                if ($Laimex)
                {
                    $ldifArguments += '-user "{0}"' -f $Credential.UserName
                    $ldifArguments += '-pwd "{0}"' -f $password
                }
                else
                {
                    $account = $matches['account']
                    $domain = $matches['domain']
                    $ldifArguments += ('-b "{0}" "{1}" "{2}"' -f $account, $domain, $password)
                }
            }
            elseif (($Credential.UserName -match '\A(?<domain>[A-Z0-9]+)\\(?<account>.+)\Z')) # DOMAIN\account format
            {
                if ($Laimex)
                {
                    $ldifArguments += '-user "{0}"' -f $Credential.UserName
                    $ldifArguments += '-pwd "{0}"' -f $password
                }
                else
                {
                    $account = $matches['account']
                    $domain = $matches['domain']
                    $ldifArguments += ('-b "{0}" "{1}" "{2}"' -f $account, $domain, $password)
                }
            }
            else #assume DN format
            {
                if ($Laimex)
                {
                    $ldifArguments += '-user "{0}"' -f $Credential.UserName
                    $ldifArguments += '-pwd "{0}"' -f $password
                }
                else
                {
                    $ldifArguments += ('-a "{0}" "{1}"' -f $Credential.UserName, $password)
                }
            }
        }

        if (!$Laimex)
        {
            $ldifArguments += '-j "{0}"' -f $env:TEMP
        }

        foreach ($a in $ldifArguments)
        {
            Write-Debug $a
        }
    }

    end
    {
        $x = Start-Process -FilePath $cmd -ArgumentList $ldifArguments -NoNewWindow -RedirectStandardOutput out.txt -PassThru -Wait
        Write-Verbose $x.ExitCode
        Remove-Item out.txt
		if ($x.ExitCode -eq 0)
		{
			Write-Output $true
		}
		else
		{
			Write-Output $false
		}
    }
}

Export-ModuleMember -Function Read-Ldif
