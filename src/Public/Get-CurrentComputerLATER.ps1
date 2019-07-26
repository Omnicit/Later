function Get-CurrentComputerLATER {
    <#
    .SYNOPSIS
    Finds admin password for given computer

    .DESCRIPTION
    Finds local admin password and password expiration timestamp for given computer

    .EXAMPLE
    Get-CurrentComputerLATER -ComputerName CLIENT012

    Gets password of local administrator on computer CLIENT012

    #>
    [CmdletBinding(
        SupportsShouldProcess
    )]
    param (
        # Input a valid Computer Name to request local administrator password.
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

                $BaseQuery = @"
SELECT TOP 10 [UserId]
      ,[ComputerName]
      ,[ComputerIPAddress]
      ,[Timestamp]
FROM [Later].[dbo].[Requests] WHERE UserId = 'REPLACEUSERNAME' Order By TimeStamp Desc
"@

                $SQLQuery = $BaseQuery -replace 'REPLACEUSERNAME', $PSSenderInfo.ConnectedUser
                [Object[]]$PastLater = Invoke-DbaQuery -SqlInstance localhost -Database Later -Query $SQLQuery

                $TimeStampString = $PastLater.TimeStamp.ForEach( { $_.ToString() })
                $Now = [datetime]::Now
                $RequestsToday = ($TimeStampString -replace '\s.*$') -match $Today

                if ($RequestsToday -ge 3) {
                    throw ('No more requests allowed for {0} today' -f $PSSenderInfo.ConnectedUser)
                }
                elseif ($Result[0].Timestamp -ge $Now.AddHours(-1)) {
                    throw ('Request already submitted for this user, wait time {0} Minutes' -f ($Result[0].Timestamp - $Now.AddHours(-1)).Minutes)
                }
                else {
                    Get-AdmPwdPassword -ComputerName $ComputerName
                    [PSCustomObject]@{
                        UserId            = $PSSenderInfo.ConnectedUser
                        ComputerName      = $ComputerName
                        ComputerIPAddress = $WSManInstance.ClientIP
                    } | Write-DbaDbTableData -SqlInstance localhost -Database Later -Table Requests
                }
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}