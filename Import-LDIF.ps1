<#
 .Synopsis
  Imports directory information from an LDIF file.

 .Description
  Imports directory information from an LDIF file, and writes custom PowerShell objects to the pipeline.
  
 .Parameter Path
  Path to the LDIF file
  
 .Example
   Import-LDIF '.\TestUsers.ldif'
#>

function Import-LDIF 
{
    param ([Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Path)

    # First we resolve the path and open the file
    begin
    {
        $name = Resolve-Path $Path
        $f = [System.IO.File]::OpenText($name)
    }

    
    process
    {

        while (-not $f.EndOfStream) 
        {
            $line = $f.ReadLine()

            while( $f.Peek() -eq 32 )
            {
                $continue = $f.ReadLine()
                $line += $continue.Trim()
            }

            # If the version marker is there, ignore it
            if ($line -match '^version.+$')
            {
                continue
            }
            
            # Ignore comment lines
            if ($line -match '^#.*$')
            {
                continue
            }

            # If it is DN, then we are starting a new object
            if ($line -match '^dn:.+$')
            {
                $ldifEntry = New-Object System.Management.Automation.PSObject
                # Give object a type name which can be identified later
                $ldifEntry.PSObject.TypeNames.Insert(0,’LDIFEntry’)
                
            }

            # If it is an empty line, then we are finished for this object
            # Ship it!
            if ($line -match '^$')
            {
                Write-Output $ldifEntry
                #Write-Host '.' -NoNewLine
                continue
            }

            # Break the line into parts for parsing
            
            $parts = $line.Split(':')
            
            $attributeName = $parts[0]

            # If there are two parts, it is a regular <attribute>: <value> line
            if ( $parts.Count -eq 2 )
            {
                
                if (Get-Member -InputObject $ldifEntry -Name $attributeName)
                {
                    if ($ldifEntry.$attributeName.GetType().Name -ne 'Object[]')
                    {
                        $vals = $ldifEntry.$attributeName
                        $ldifEntry.$attributeName = @($vals)
                    }
                    $ldifEntry.$attributeName += $($parts[1].Trim())
                }
                else
                {
                    Add-Member -InputObject $ldifEntry -Name $attributeName -Value $parts[1].Trim() -MemberType NoteProperty
                }
            }
            
            if ( $parts.Count -eq 3 ) # means we have a binary attribute
            {
                $attributeName += ';binary'
                if (Get-Member -InputObject $ldifEntry -Name $attributeName)
                {
                    if ($ldifEntry.$attributeName.GetType().Name -ne 'Object[]')
                    {
                        $vals = $ldifEntry.$attributeName
                        $ldifEntry.$attributeName = @($vals)
                    }

                    $ldifEntry.$attributeName += $($parts[2].Trim())
                }
                else
                {
                    Add-Member -InputObject $ldifEntry -Name $attributeName -Value $parts[2].Trim() -MemberType NoteProperty
                }
            }
        }

    }
    
    end
    {
        $f.Close()
    }
}


# SIG # Begin signature block
# MIIO/gYJKoZIhvcNAQcCoIIO7zCCDusCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUy7rTUNhjPxjKAO7wt9YIK+Vs
# coegggxpMIIFhjCCBG6gAwIBAgIKFhJcIwAAAAAACjANBgkqhkiG9w0BAQUFADBQ
# MRQwEgYKCZImiZPyLGQBGRYEaG9tZTEZMBcGCgmSJomT8ixkARkWCWJvb3RoYmls
# dDEdMBsGA1UEAxMUQm9vdGhCaWx0LUlzc3VpbmctQ0EwHhcNMTAxMDIyMjIxMTI0
# WhcNMjAxMDE5MjIxMTI0WjAWMRQwEgYDVQQDEwtKYW1lcyBCb290aDCCASIwDQYJ
# KoZIhvcNAQEBBQADggEPADCCAQoCggEBANYDDQi6xr8Ya9QbVTKdJUQwOfN9bJIp
# DAlSnYEHrRMLfAsKxogv92MZN2P5v5WbI8uVwnnkQXeOINH+C/5uiIUWwmPPM8jv
# ZQEOYIJzPXyN7Bs0cSqoBk5DXBa7uZubaQjDLNJfe/BoOndmfhX5J26aKghS5obT
# GBI+oP9fPbGLf83ydvCqdtTnmTe0vfWrLTTbk96ed9Cj/yBjsIeu6PNFTpQImxpN
# fAV1PCF14w3yeRCECt6VFNmWToGMBWx1+81JlmiyzDSpfdDVL/ZYD4H0jpFVBeoa
# 2KnSK/2UguiYpFYyIzlmqVP7/+ecU8JvCccwFV8Acj/QI8WGhdGMEeMCAwEAAaOC
# ApowggKWMA4GA1UdDwEB/wQEAwIHgDA7BgkrBgEEAYI3FQcELjAsBiQrBgEEAYI3
# FQiBlexFh+y/IILhiyi/4x6Hl88aFYWzvU2Y6AsCAWQCAQMwHQYDVR0OBBYEFGKz
# iFFHEq8EsttCQXY3p9epTmn5MB8GA1UdIwQYMBaAFEct0+1wFw+nva/mYKu5ipP7
# yWO+MIHXBgNVHR8Egc8wgcwwgcmggcaggcOGgcBsZGFwOi8vL0NOPUJvb3RoQmls
# dC1Jc3N1aW5nLUNBLENOPXZlc3Bhc2lhbixDTj1DRFAsQ049UHVibGljJTIwS2V5
# JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1ib290
# aGJpbHQsREM9aG9tZT9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2Jq
# ZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwgckGCCsGAQUFBwEBBIG8MIG5
# MIG2BggrBgEFBQcwAoaBqWxkYXA6Ly8vQ049Qm9vdGhCaWx0LUlzc3VpbmctQ0Es
# Q049QUlBLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENO
# PUNvbmZpZ3VyYXRpb24sREM9Ym9vdGhiaWx0LERDPWhvbWU/Y0FDZXJ0aWZpY2F0
# ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMwGwYJKwYBBAGCNxUKBA4wDDAKBggrBgEFBQcDAzAvBgNV
# HREEKDAmoCQGCisGAQQBgjcUAgOgFgwUamFtZXNAYm9vdGhiaWx0LmhvbWUwDQYJ
# KoZIhvcNAQEFBQADggEBACnaWi3aL0/i/p5WWGdHa+eeHeUJdwI5I5tBxzQ/lhU3
# VbVzHlm6zmiEbV3UfgdMLI0X1qT1PwuJKSsx/KoGG+DLKSzoE0IykzDc0h+qXwip
# 6OILWnmhcMvOx9Ft7mjem90G/wv56c3DP5Gz+m7+e5YSeYIQrwrCR+AQns7E7JNU
# 6jI4w5nUvCKZXmHI74/m+IuzNel5D/4Oau99Uw5ns6uI9qN+qst2XA6ZTkPdZ/vv
# aAzPF2GajMtK1MAMKTYZbb6IyuQeQGTl0zTCQQtTKljtgInO3K6zJGFtsYvGVFqj
# PUBZ3B1QWTz5pR1VEvcI4SAtYptisL96svKYqtFKeJcwggbbMIIEw6ADAgECAgph
# XyGjAAAAAAADMA0GCSqGSIb3DQEBBQUAMEgxFDASBgoJkiaJk/IsZAEZFgRob21l
# MRkwFwYKCZImiZPyLGQBGRYJYm9vdGhiaWx0MRUwEwYDVQQDEwxCT09USEJJTFQt
# Q0EwHhcNMTAxMDIxMjAyMDAwWhcNMzAxMDIxMTgxNzQxWjBQMRQwEgYKCZImiZPy
# LGQBGRYEaG9tZTEZMBcGCgmSJomT8ixkARkWCWJvb3RoYmlsdDEdMBsGA1UEAxMU
# Qm9vdGhCaWx0LUlzc3VpbmctQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQCg0iiiToD3nwQDR4RS3+pu7FHsnlkflHTWmApmoXdEf/03iMZ3MQTjXL2o
# yes8Cuiv8ABUDFrK+0Xevgk3geP7RpVWYQmL1WCYcGtLKLBl0APK8BMQeIX5ailG
# hjdBmFtg19jlvLn8ZAHeU0Xgr24zZWiidiyo33RS+ubJPemedL69lOhxaTS4H/Rp
# lG5FJXCdNakZYWu7iiU3m0QRcp08L5q/m8wDxjZgVGdjYoDtd63N11CIIaefpsfv
# D9iCUpPq0GJprcrlylDjHN7BvoxeQ7vVTj0ozBFZXQK8HBQW9+S6VGwi92u4kPxs
# 7hUC0H7IReSCh4b1P7r+4NTkLdXZAgMBAAGjggK9MIICuTAQBgkrBgEEAYI3FQEE
# AwIBADAdBgNVHQ4EFgQURy3T7XAXD6e9r+Zgq7mKk/vJY74wGQYJKwYBBAGCNxQC
# BAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYD
# VR0jBBgwFoAUnUgimdbQ/u5docDtcUZmOn3TnpUwggEPBgNVHR8EggEGMIIBAjCB
# /6CB/KCB+YaBu2xkYXA6Ly8vQ049Qk9PVEhCSUxULUNBLENOPUJvb3RoQmlsdC1D
# QSxDTj1DRFAsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMs
# Q049Q29uZmlndXJhdGlvbixEQz1ib290aGJpbHQsREM9aG9tZT9jZXJ0aWZpY2F0
# ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2JqZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9u
# UG9pbnSGOWh0dHA6Ly92ZXNwYXNpYW4uYm9vdGhiaWx0LmhvbWUvQ2VydERhdGEv
# Qk9PVEhCSUxULUNBLmNybDCCARcGCCsGAQUFBwEBBIIBCTCCAQUwga4GCCsGAQUF
# BzAChoGhbGRhcDovLy9DTj1CT09USEJJTFQtQ0EsQ049QUlBLENOPVB1YmxpYyUy
# MEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9
# Ym9vdGhiaWx0LERDPWhvbWU/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNz
# PWNlcnRpZmljYXRpb25BdXRob3JpdHkwUgYIKwYBBQUHMAKGRmh0dHA6Ly92ZXNw
# YXNpYW4uYm9vdGhiaWx0LmhvbWUvQ2VydERhdGEvQm9vdGhCaWx0LUNBX0JPT1RI
# QklMVC1DQS5jcnQwDQYJKoZIhvcNAQEFBQADggIBAKqNMjVhDy52aPW6tzkeEudq
# b7kub/bZLiEFuHzNJ7jivXV2APog8XOuYM+hrMnCvYhu1AOhCxyRzMIgyZhJyLyj
# KmEbD41SnKvpMKKUgEkjRjeLXH15ROp132JwT/51kAICqENP9qOe28O6e/vgj7Iv
# eYqNOmVd+P4bVkdGCSFR0hwt+4xnzFOXnYlXAFlSAZJzRS1VG6v6FTk++eVJgkcq
# wJ5JTyW3MemjZ2zjK/zPSl8v2cfiGPbCgRO0hQ4Bk1eVjwAW//twwTFxt5DMAL6f
# 4qCf8gyCZFx+jhQWyTTcfWRcNNtAI9EGzznMK3hEqUZP0erKCftExltieTuzQLwy
# aKImBJHtuuMThz4Tp9UI+UHkBOWQbZEWGmMfOzvIHdPueCxOyTKpaLGHrEgqdeHt
# 1UFPSvMAHHx/yGM+FM1Iaz/96drOazg55bRjwqPlJxhlyUKMImVsdc17snN15hC4
# NkgeMAU0LuIPCCgzdpUvj+9MmKAUPkN+pj5EW248+JYbXHu8kabwOnnMSKFEcpHJ
# nk2XeQGCYGquQ1Fe18YwINE+c4fdAE5g6zu9oU/lCqj7pMJ+fcNEGlvFmQ4owg1z
# uzSOhLMY4JYztufGAWbfSOSNeGm99b09uckE7R0wXosGOl4B5s58Pa1o3A89KGr8
# kNCoY4WQj8aEHy1V8Kh6MYIB/zCCAfsCAQEwXjBQMRQwEgYKCZImiZPyLGQBGRYE
# aG9tZTEZMBcGCgmSJomT8ixkARkWCWJvb3RoYmlsdDEdMBsGA1UEAxMUQm9vdGhC
# aWx0LUlzc3VpbmctQ0ECChYSXCMAAAAAAAowCQYFKw4DAhoFAKB4MBgGCisGAQQB
# gjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDT51YZ0
# 8bJtBhekzYDUFxMZ3yAjMA0GCSqGSIb3DQEBAQUABIIBAKOHPeImyGe5RdgBBGYE
# gW6dGvN2ENK/VT+qDmDu973y/3iI+rvfWWVjCH0wvPjPAwhrk/CDnqwpJg3Elfwu
# /8DY7y7QndgqSJPVkjEZDDbzPqD3n0bFYS4HIK3f8lNk+X3mFOOGENFZiziMgUPc
# 1cH1+lCX+PBV7EK+D282wIyjC5lghzXLwF4F9JJyssFPqUUkEN7cJqnEsj+kB/nt
# LpJgpjv2tse8OrTyEKSjLRAscgOTSN1pmfWbNoLFzeRTRLiQHaAyMNqsxF/DHc8W
# DXxuGoP6X5IVhC88rrQzGRqj2/a2sD6cG/cPYdr7qApQpUo1M/yhpUvuKis0BBCU
# jMw=
# SIG # End signature block
