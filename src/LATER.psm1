[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
# Script variables used to point ut the SQL Instance
[string]$Database = 'Later'
[string]$Schema = 'dbo'
[string]$SqlInstance = 'localhost'

# All L.A.T.E.R Active Directory Groups are named with the prefix 'res-sys-later'

# Unblock files.
Get-ChildItem -Path $PSScriptRoot -Recurse | Unblock-File

# Dot source private functions.
Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 | ForEach-Object { . $_.FullName }
# Dot source public functions.
Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 | ForEach-Object { . $_.FullName }

