# LDIFTools

## LDIFTools PowerShell Module

A few PowerShell cmdlets and functions to make working with [LDAP Data Interchange Format (LDIF)](https://www.rfc-editor.org/rfc/rfc2849) files a bit easier.

This project started as an itch I needed to scratch in 2009 or 2010, when working a bunch of projects involving LDAP servers of many kinds. I was enamoured (still am) with PowerShell and wanted to use it as much as possible. I was using Import-Csv and Import-Clixml quite a bit and thought it would be a good idea to have an Import-Ldif to convert all those LDIF dump files into PSObjects I could slice, dice, and julienne in any way I saw fit. Cmdlets in C# seemed like the best way to go, and so it began. I posted version 1.0 on github in 2011. 

The PowerShell and .NET landscape has changed a lot since then, and I figured it was time for an update. The new version is built as a Microsoft.NET.Sdk project and Import-Ldif and Export-Ldif run just fine in Linux environments. 

## Module Commands

* [Import-Ldif](docs/Import-Ldif.md)
* [Export-Ldif](docs/Export-Ldif.md)
* [Read-Ldif](docs/Read-Ldif.md)

## Future Versions

It occurs to me now (2022) that it might be nice to have a Compare-Ldif cmdlet as well, to compare two sets of LDIF objects and produce a set of add, modify, and delete operations that could be applied to make the two directories look the same. 

If you have any suggestions for enhancements or bug reports, please use the Issues section of this repository.

