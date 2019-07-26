$CapabilityFileParams = @{
    'Path'            = "C:\JEA\Requester.psrc"
    'Author'          = "Omnicit AB" 
    'CompanyName'     = 'Omnicit AB'
    'Description'     = 'JEA capability file for LATER.'
    'ModulesToImport' = 'LATER'
}

New-PSRoleCapabilityFile @CapabilityFileParams