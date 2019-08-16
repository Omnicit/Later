# Script variables used to point ut the SQL Instance
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '', Justification = "Used in functions")]
[string]$Database = 'Later'
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '', Justification = "Used in functions")]
[string]$Schema = 'dbo'
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '', Justification = "Used in functions")]
[string]$SqlInstance = 'localhost'

# All L.A.T.E.R Active Directory Groups are named with the prefix 'res-sys-later'

# Unblock files.
Get-ChildItem -Path $PSScriptRoot -Recurse | Unblock-File

# Dot source private functions.
Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 | ForEach-Object { . $_.FullName }
# Dot source public functions.
Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 | ForEach-Object { . $_.FullName }

