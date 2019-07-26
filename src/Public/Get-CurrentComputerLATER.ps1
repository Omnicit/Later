function Get-CurrentComputerLATER {
    [CmdletBinding(
        SupportsShouldProcess
    )]
    param (
        # Parameter help description
        [Parameter(
            Mandatory
        )]
        [ValidateNotNullOrEmpty]
        $ComputerName
    )
    process {
        if ($PSCmdlet.ShouldProcess($ComputerName, $MyInvocation.MyCommand.Name)) {
            try {
                # Get session configuration
                $PSSenderInfo
                $WSManInstance = Get-WSManInstance -ComputerName localhost -ResourceURI Shell -Enumerate

                #$WSManInstance.ClientIP
                
                #Get SQL TABLE current user
                #compare againast timestamp
                # if valid timestamps
                #Request LAPS PW 
                # else FAIL
                
                

            }
            catch {

            }
        }
    }
}