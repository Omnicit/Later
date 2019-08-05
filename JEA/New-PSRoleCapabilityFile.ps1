$CapabilityFileParams = @{
    'Path'             = "C:\Program Files\WindowsPowerShell\Modules\LATER\RoleCapabilities\Requester.psrc"
    'Author'           = "Omnicit AB"
    'CompanyName'      = 'Omnicit AB'
    'Description'      = 'JEA capability file for LATER.'
    'VisibleFunctions' = @('Get-CurrentComputerLATER', 'Reset-CurrentComputerLATER')
}

New-PSRoleCapabilityFile @CapabilityFileParams