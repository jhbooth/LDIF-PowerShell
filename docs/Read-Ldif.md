﻿# Read-Ldif

## SYNOPSIS
Reads LDIF data from an LDAP server and writes it to file.

## SYNTAX

### ldifde (Default)
```
Read-Ldif [-Server] <String> [-Path] <String> [-Port <Int32>] [-SearchBase <String>] [-LdapFilter <String>] [-Scope <String>] [-Include <String[]>] [-Exclude <String[]>] [-Credential <PSCredential>] [-Ldifde] [<CommonParameters>]
```

### laimex
```
Read-Ldif [-Server] <String> [-Path] <String> [-Port <Int32>] [-SearchBase <String>] [-LdapFilter <String>] [-Scope <String>] [-Include <String[]>] [-Credential <PSCredential>] [-Laimex] [<CommonParameters>]
```

## DESCRIPTION
Wraps command line tools to retrieve LDIF files from LDAP Servers; by default, uses ldifde.exe, but can also use laimex.exe from Softerra.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
PS C:\\\>
```powershell
Read-Ldif -Path 'local.ldf' -Server 'localhost'
```

### -------------------------- EXAMPLE 2 --------------------------
PS C:\\\>
```powershell
Read-Ldif localhost schema.ldif -SearchBase '#schemaNamingContext'
```

Reads schema information from a local AD LDS instance.

## PARAMETERS

### Server
Name of the server from which the LDIF will be read.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: true
Position: 0
Default Value: 
Pipeline Input: false
```

### Path
Path to an LDIF file to contain the output

```yaml
Type: String
Parameter Sets: (All)
Aliases: FilePath

Required: true
Position: 1
Default Value: 
Pipeline Input: false
```

### Port
Port used to connect to LDAP server; default 389

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: 

Required: false
Position: named
Default Value: 389
Pipeline Input: false
```

### SearchBase
The root DN where the search will be run.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: false
Position: named
Default Value: 
Pipeline Input: false
```

### LdapFilter
Search filter to use; default is (objectClass=\*)

```yaml
Type: String
Parameter Sets: (All)
Aliases: Filter

Required: false
Position: named
Default Value: (objectClass=*)
Pipeline Input: false
```

### Scope
Search scope - one of Base, OneLevel, or Subtree; default is Subtree

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: false
Position: named
Default Value: Subtree
Accepted Values: Base
                 OneLevel
                 Subtree
Pipeline Input: false
```

### Include
A list of attribute names to be retrieved by the search.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: false
Position: named
Default Value: 
Pipeline Input: false
```

### Exclude
A list of attribute names to be excluded from the search.

```yaml
Type: String[]
Parameter Sets: ldifde
Aliases: 

Required: false
Position: named
Default Value: 
Pipeline Input: false
```

### Credential
A PSCredential object with credentials needed to connect to the server.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: 

Required: false
Position: named
Default Value: 
Pipeline Input: false
```

### Ldifde


```yaml
Type: SwitchParameter
Parameter Sets: ldifde
Aliases: 

Required: false
Position: named
Default Value: True
Pipeline Input: false
```

### Laimex


```yaml
Type: SwitchParameter
Parameter Sets: laimex
Aliases: 

Required: false
Position: named
Default Value: False
Pipeline Input: false
```

### \<CommonParameters\>
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Boolean


## NOTES

.

## RELATED LINKS

[Laimex.exe](https://www.ldapadministrator.com/features.htm#import)

[ldifde.exe](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/cc731033(v=ws.11))

[Import-Ldif]()

[Link 4]()


*Generated by: PowerShell HelpWriter 2022 v2.3.54*