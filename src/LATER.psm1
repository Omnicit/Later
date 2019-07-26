#Unblock files.
Get-ChildItem -Path $PSScriptRoot -Recurse | Unblock-File

#Dot source private functions.
Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 | Foreach-Object { . $_.FullName }
#Dot source public functions.
Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 | Foreach-Object { . $_.FullName }