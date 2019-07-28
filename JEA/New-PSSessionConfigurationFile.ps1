$SessionParams = @{
    'Path'                = "C:\JEA\Requester.pssc"
    'LanguageMode'        = 'NoLanguage'
    'ExecutionPolicy'     = 'RemoteSigned'
    'SessionType'         = 'Default'
    'TranscriptDirectory' = 'C:\PSTranscripts\'
    'Author'              = 'Omnicit AB'
    'ModulesToImport'     = 'LATER'
    'RoleDefinitions'     = @{ 'CONTOSO\res-sys-later requester' = @{ RoleCapabilities = 'Requester' } }
}

New-PSSessionConfigurationFile @SessionParams

$RegisterParams = @{
    'Name'                     = 'LATER'
    'Path'                     = "C:\JEA\Requester.pssc"
    'ShowSecurityDescriptorUI' = $True
}

Register-PSSessionConfiguration @RegisterParams

# $JEA = Get-PSSessionConfiguration -Name LATER

$RunAsCred = (Get-Credential 'CONTOSO\svc-admpwd')
Set-PSSessionConfiguration -Name LATER -RunAsCredential $RunAsCred

# Unregister-PSSessionConfiguration -Name LATER -Force