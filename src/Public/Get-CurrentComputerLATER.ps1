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
    begin {
        [string]$TablePolicy = 'Policy'
        [string]$TableRequests = 'Requests'
        [string]$TableFailedRequests = 'FailedRequests'

        $BasePolicyQuery = @"
SELECT [Id]
      ,[GroupId]
      ,[Computers]
      ,[TimesPerDay]
FROM [$Database].[$Schema].[$TablePolicy] WHERE GroupId IN (REPLACESID)
"@
        $BasePastLaterQuery = @"
SELECT TOP 1000 [UserId]
      ,[ComputerName]
      ,[Timestamp]
FROM [$Database].[$Schema].[$TableRequests] WHERE UserId = 'REPLACESID' Order By TimeStamp Desc
"@
    }
    process {
        if ($PSCmdlet.ShouldProcess($ComputerName)) {
            try {
                $Request = Get-LaterRequesterInfo -ComputerName $ComputerName -ErrorAction Stop

                $PolicySQLQuery = $BasePolicyQuery -replace 'REPLACESID', ("'{0}'" -f ($Request.UserPolicyGroups -join "', '"))
                try {
                    [Object[]]$Policies = Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $PolicySQLQuery -ErrorAction Stop | Sort-Object -Property Computer
                    $Policy = $Policies[0]
                    # Preferably log that the user has more than one policy if ($Policies.Count -gt 1)
                }
                catch {
                    throw [System.AccessViolationException]::New('No L.A.T.E.R policy found for user.')
                }

                $PastLaterSQLQuery = $BasePastLaterQuery -replace 'REPLACESID', $Request.UserId
                [Object[]]$PastLater = Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $PastLaterSQLQuery -ErrorAction Stop

                $Request.psobject.Properties.Remove('UserPolicyGroups')
                $Now = [datetime]::Now
                if ($null -ne $PastLater) {
                    $ThrottleReached = $false
                    $CurrentComputerPastLater = $PastLater | Where-Object { $_.ComputerName -eq $ComputerName }
                    $CurrentComputerTimeStampString = $CurrentComputerPastLater.TimeStamp.ForEach( { $_.ToString() })
                    $CurrentComputerRequestsToday = ($CurrentComputerTimeStampString -replace '\s.*$') -match $Today
                    $TimeStampString = $PastLater.TimeStamp.ForEach( { $_.ToString() })
                    $RequestsToday = ($TimeStampString -replace '\s.*$') -match $Today

                    if (([array]$RequestsToday).Count -gt ($Policy.TimesPerDay * $Policy.Computers)) {
                        $ThrottleReached = $true
                        $ErrorNotification = 'No more requests allowed for {0} today.' -f $Request.UserId
                    }
                    elseif (([array]$CurrentComputerRequestsToday).Count -gt $Policy.TimesPerDay) {
                        $ThrottleReached = $true
                        $ErrorNotification = 'No more requests allowed for user {0} on computer name {1} today.' -f $Request.UserId, $ComputerName
                    }
                    elseif (([array]$PastLater.ComputerName | Sort-Object -Unique).Count -gt $Policy.Computers) {
                        $ThrottleReached = $true
                        $ErrorNotification = 'User {0} only permitted to request for {1} computers. Limit reached, contact support.' -f $Request.UserId, $Policy.Computers
                    }
                    elseif ($CurrentComputerPastLater.Timestamp[0] -ge $Now.AddHours(-1)) {
                        $ThrottleReached = $true
                        $ErrorNotification = 'Request already submitted for {0}, wait time {1} Minutes.' -f $Request.UserId, ($PastLater[0].Timestamp - $Now.AddHours(-1)).Minutes
                    }
                    if ($ThrottleReached) {
                        $Request | Add-Member -MemberType NoteProperty -Name Error -Value $ErrorNotification -ErrorAction Stop
                        $Request | Write-DbaDbTableData -SqlInstance $SqlInstance -Database $Database -Table $TableFailedRequests -ErrorAction Stop
                        throw [System.AccessViolationException]::New($ErrorNotification -replace ($Request.UserId, ($PSSenderInfo.ConnectedUser -replace '^(?:.+\\)')))
                    }
                }
                try {
                    Get-AdmPwdPassword -ComputerName $ComputerName -ErrorAction Stop
                    $Request | Write-DbaDbTableData -SqlInstance $SqlInstance -Database $Database -Table $TableRequests -ErrorAction Stop
                }
                catch {
                    $ErrorNotification = 'Unknown error: {0}' -f $_.Exception.Message
                    $Request | Add-Member -MemberType NoteProperty -Name Error -Value $ErrorNotification -ErrorAction Stop
                    $Request | Write-DbaDbTableData -SqlInstance $SqlInstance -Database $Database -Table $TableFailedRequests -ErrorAction Stop
                    throw [System.SystemException]::New($ErrorNotification)
                }
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}