function Get-CurrentComputerLATER {
    <#
    .SYNOPSIS
    Finds admin password for current computer

    .DESCRIPTION
    Finds local admin password and password expiration timestamp for current computer

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
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )
    process {
        if ($PSCmdlet.ShouldProcess($ComputerName, $MyInvocation.MyCommand.Name)) {
            try {
                $WSManInstance = Get-WSManInstance -ConnectionURI $PSSenderInfo.ConnectionString -ResourceURI shell -Enumerate

                $BaseQuery = @"
SELECT TOP 10 [UserId]
      ,[ComputerName]
      ,[ComputerIPAddress]
      ,[Timestamp]
FROM [Later].[dbo].[Requests] WHERE UserId = 'REPLACEUSERNAME' Order By TimeStamp Desc
"@

                $SQLQuery = $BaseQuery -replace 'REPLACEUSERNAME', $PSSenderInfo.ConnectedUser
                [Object[]]$PastLater = Invoke-DbaQuery -SqlInstance localhost -Database Later -Query $SQLQuery
                $Now = [datetime]::Now

                if ($null -ne $PastLater) {
                    $TimeStampString = $PastLater.TimeStamp.ForEach( { $_.ToString() })
                    $RequestsToday = ($TimeStampString -replace '\s.*$') -match $Today
                    if ($RequestsToday -ge 3) {
                        $ErrorNotification = 'No more requests allowed for {0} today' -f $PSSenderInfo.ConnectedUser
                        [PSCustomObject]@{
                            UserId            = $PSSenderInfo.ConnectedUser
                            ComputerName      = $ComputerName
                            ComputerIPAddress = $WSManInstance.ClientIP
                            Error             = $ErrorNotification
                        } | Write-DbaDbTableData -SqlInstance localhost -Database Later -Table FailedRequests
                        throw [System.AccessViolationException]::New($ErrorNotification)
                    }
                    elseif ($PastLater[0].Timestamp -ge $Now.AddHours(-1)) {
                        $ErrorNotification = 'Request already submitted for this user, wait time {0} Minutes' -f ($PastLater[0].Timestamp - $Now.AddHours(-1)).Minutes
                        [PSCustomObject]@{
                            UserId            = $PSSenderInfo.ConnectedUser
                            ComputerName      = $ComputerName
                            ComputerIPAddress = $WSManInstance.ClientIP
                            Error             = $ErrorNotification
                        } | Write-DbaDbTableData -SqlInstance localhost -Database Later -Table FailedRequests

                        throw [System.AccessViolationException]::New($ErrorNotification)
                    }
                }
                Get-AdmPwdPassword -ComputerName $ComputerName
                [PSCustomObject]@{
                    UserId            = $PSSenderInfo.ConnectedUser
                    ComputerName      = $ComputerName
                    ComputerIPAddress = $WSManInstance.ClientIP
                } | Write-DbaDbTableData -SqlInstance localhost -Database Later -Table Requests
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}