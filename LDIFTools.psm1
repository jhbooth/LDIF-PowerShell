
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
        A PSCredential object with credentials needed to connect to the server.

    .PARAMETER Include
        A list of attribute names to be retrieved by the search.

    .PARAMETER Exclude
        A list of attribute names to be excluded from the search.


    .EXAMPLE
        PS C:\> Read-Ldif -Path 'local.ldf' -Server 'localhost' 

	.EXAMPLE
		PS C:\> Read-Ldif localhost schema.ldif -SearchBase '#schemaNamingContext'

		Reads schema information from a local AD LDS instance.

    .NOTES

.
#>
function Read-Ldif
{
	[CmdletBinding(DefaultParameterSetName = 'ldifde')]
	[OutputType([Boolean])]
	param
	(
		[Parameter(Mandatory = $true, ParameterSetName = 'ldifde', Position = '0')]
		[Parameter(Mandatory = $true, ParameterSetName = 'laimex', Position = '0')]
		[string]$Server,
		[ValidateNotNullOrEmpty()]
		[Alias('FilePath')]
		[Parameter(Mandatory = $true, ParameterSetName = 'ldifde', Position = '1')]
		[Parameter(Mandatory = $true, ParameterSetName = 'laimex', Position = '1')]
		[string]$Path,
		[Parameter(ParameterSetName = 'ldifde')]
		[Parameter(ParameterSetName = 'laimex')]
		[int]$Port = 389,
		[Parameter(ParameterSetName = 'ldifde')]
		[Parameter(ParameterSetName = 'laimex')]
		[string]$SearchBase,
		[Parameter(ParameterSetName = 'ldifde')]
		[Parameter(ParameterSetName = 'laimex')]
		[Alias('Filter')]
		[string]$LdapFilter = '(objectClass=*)',
		[Parameter(ParameterSetName = 'ldifde')]
		[Parameter(ParameterSetName = 'laimex')]
		[ValidateSet('Base', 'OneLevel', 'Subtree')]
		[string]$Scope = 'Subtree',
		[Parameter(ParameterSetName = 'ldifde')]
		[Parameter(ParameterSetName = 'laimex')]
		[string[]]$Include,
		[Parameter(ParameterSetName = 'ldifde')]
		[string[]]$Exclude,
		[Parameter(ParameterSetName = 'ldifde')]
		[Parameter(ParameterSetName = 'laimex')]
		[pscredential]$Credential,
		[Parameter(ParameterSetName = 'ldifde')]
		[switch]$Ldifde = $true,
		[Parameter(ParameterSetName = 'laimex')]
		[switch]$Laimex
		
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
			$ldifArguments += '-j "{0}"' -f $PWD
			$ldiferr = Join-Path -Path $PWD -ChildPath 'ldif.err'
			if (Test-Path -Path $ldiferr)
			{
				Remove-Item $ldiferr
			}
		}
	}
	
	end
	{
		Write-Debug -Message "Running: $cmd"
		Write-Debug -Message "Arguments: $($ldifArguments -join ' ')"
		
		$x = Start-Process -FilePath $cmd -ArgumentList $ldifArguments -NoNewWindow -RedirectStandardOutput out.txt -PassThru -Wait
		
		if ($Ldifde)
		{
			if ($x.ExitCode -ne 0 -or (Test-Path -Path $ldiferr))
			{
				Write-Debug -Message ("ExitCode: {0} `nldif.err:`n{1}`nout.txt:`n{2}" -f $x.ExitCode, (Get-Content $ldiferr -Raw), (Get-Content out.txt -Raw))
			}
		}
		
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

#Export-ModuleMember -Function Read-Ldif

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
	$export.PSObject.TypeNames.Insert(0, 'ExportedDirectoryCredential')
	
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
#Export-ModuleMember -Function New-DirectoryCredentialXml

#===============================================================================

function Convert-EscapeDnComponent
{
	[CmdletBinding()]
	param ([parameter(Mandatory = $true)][string]$token)
	
	$result = ($token -replace '(?<!\\)[+;,#<>"=]', '\$&')
	
	$result
}

#Export-ModuleMember -Function Convert-EscapeDnComponent

#===============================================================================

#Export-ModuleMember -Cmdlet Export-Ldif, Import-Ldif

#===============================================================================
