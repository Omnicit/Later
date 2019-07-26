$SessionParams = @{
    'Path'                = "C:\JEA\Requester.pssc"
    'LanguageMode'        = 'RestrictedLanguage'
    'ExecutionPolicy'     = 'RemoteSigned'
    'SessionType'         = 'RestrictedRemoteServer'
    'TranscriptDirectory' = 'C:\PSTranscripts\'
    'Author'              = 'Omnicit AB'
    'RoleDefinitions'     = @{ 'CONTOSO\res-sys-later requester' = @{ RoleCapabilityFiles = 'C:\JEA\Requester.psrc' }}
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

# Unregister-PSSessionConfiguration -Name LATER