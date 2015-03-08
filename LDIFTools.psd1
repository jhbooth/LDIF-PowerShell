#
# Module manifest for module 'LDIFTools'
#
# Generated by: James Booth
#

@{

# Script module or binary module file associated with this manifest
# RootModule = 'ldiftools.dll'

# Version number of this module.
ModuleVersion = '1.0.1.0'

# ID used to uniquely identify this module
GUID = 'b39e39de-0c41-46fd-b9de-aaac628ce507'

# Author of this module
Author = 'James Booth'

# Company or vendor of this module
CompanyName = 'BoothBilt'

# Copyright statement for this module
Copyright = '(c) 2012-2015 James Booth. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Functions for working with LDIF files'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '2.0'

# Name of the Windows PowerShell host required by this module
PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
PowerShellHostVersion = ''

# Minimum version of the .NET Framework required by this module
DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = ''

# Processor architecture (None, X86, Amd64, IA64) required by this module
ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module
ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @()

# Modules to import as nested modules of the module specified in ModuleToProcess
NestedModules = @("ldiftools.dll","ReadLdif.psm1")

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = @('Import-Ldif','Export-Ldif')

# Variables to export from this module
# VariablesToExport = '*'

# Aliases to export from this module
# AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @("$PSSCriptRoot\ldiftools.dll","$PSSCriptRoot\ldiftools.psm1")

# List of all files packaged with this module
FileList = ''

# Private data to pass to the module specified in ModuleToProcess
PrivateData = ''

}
