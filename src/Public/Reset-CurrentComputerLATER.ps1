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
    begin {
        [string]$TablePasswordResets = 'PasswordResets'
    }
    process {
        if ($PSCmdlet.ShouldProcess($ComputerName)) {
            try {
                $Request = Get-LaterRequesterInfo -ComputerName $ComputerName -ErrorAction Stop
                $Request.psobject.Properties.Remove('UserPolicyGroups')

                $Reset = Reset-AdmPwdPassword -ComputerName $ComputerName -ErrorAction Stop
                $Request | Add-Member -MemberType NoteProperty -Name Status -Value $Reset.Status -ErrorAction Stop
                $Request | Write-DbaDbTableData -SqlInstance $SqlInstance -Database $Database -Table $TablePasswordResets -ErrorAction Stop
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}