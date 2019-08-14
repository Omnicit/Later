function Reset-CurrentComputerLATER {
    <#
    .SYNOPSIS
    Reset admin password for given computer

    .DESCRIPTION
    Reset local admin password and password expiration timestamp for given computer

    .EXAMPLE
    Reset-CurrentComputerLATER -ComputerName CLIENT012

    Reset password of local administrator on computer CLIENT012

    #>
    [CmdletBinding(
        SupportsShouldProcess
    )]
    param (
        # Input a valid Computer Name to request local administrator password.
        [Parameter(
            Mandatory
        )]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )
    process {
        if ($PSCmdlet.ShouldProcess($ComputerName, $MyInvocation.MyCommand.Name)) {
            try {
                Reset-AdmPwdPassword -ComputerName $ComputerName -ErrorAction Stop
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}