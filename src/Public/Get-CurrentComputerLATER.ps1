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
                $WSManInstance = Get-WSManInstance -ConnectionURI $PSSenderInfo.ConnectionString -ResourceURI shell -Enumerate -ErrorAction Stop
                try {
                    $ComputerNameByAddress = ([System.Net.Dns]::GetHostByAddress($WSManInstance.ClientIP).HostName)
                }
                catch {
                    $ComputerNameByAddress = 'NULL'
                }

                $User = Get-ADUser -Identity ($PSSenderInfo.ConnectedUser -replace '^(?:.+\\)') -ErrorAction Stop
                $UserPolicyGroups = Get-ADPrincipalGroupMembership -Identity $User -ErrorAction Stop | Where-Object { $_.SamAccountName -match '^(res-sys-later.*$)' }
                $Request = [PSCustomObject]@{
                    UserId                = $User.ObjectGUID.Guid
                    ComputerName          = $ComputerName
                    ComputerNameByAddress = $ComputerNameByAddress
                    ComputerIPAddress     = $WSManInstance.ClientIP
                }

                $BasePolicyQuery = @"
SELECT [Id]
      ,[GroupId]
      ,[Computer]
      ,[TimesDay]
FROM [Later].[dbo].[Policy] WHERE GroupId IN (REPLACEGUID)
"@

                $PolicySQLQuery = $BasePolicyQuery -replace 'REPLACEGUID', ("'{0}'" -f ($UserPolicyGroups.objectGUID.Guid -join "', '"))
                try {
                    [Object[]]$Policies = Invoke-DbaQuery -SqlInstance localhost -Database Later -Query $PolicySQLQuery -ErrorAction Stop | Sort-Object -Property Computer
                    $Policy = $Policies[0]
                    # Preferably log that the user has more than one policy if ($Policies -gt 1)
                }
                catch {
                    throw [System.AccessViolationException]::New('No L.A.T.E.R policy found for user.')
                }

                $BasePastLaterQuery = @"
SELECT TOP 1000 [UserId]
      ,[ComputerName]
      ,[ComputerIPAddress]
      ,[Timestamp]
FROM [Later].[dbo].[Requests] WHERE UserId = 'REPLACEGUID' Order By TimeStamp Desc
"@

                $PastLaterSQLQuery = $BasePastLaterQuery -replace 'REPLACEGUID', $User.objectGUID.Guid
                [Object[]]$PastLater = Invoke-DbaQuery -SqlInstance localhost -Database Later -Query $PastLaterSQLQuery -ErrorAction Stop

                $Now = [datetime]::Now
                if ($null -ne $PastLater) {
                    $CurrentComputerPastLater = $PastLater | Where-Object { $_.ComputerName -eq $ComputerName }
                    $CurrentComputerTimeStampString = $CurrentComputerPastLater.TimeStamp.ForEach( { $_.ToString() })
                    $CurrentComputerRequestsToday = ($CurrentComputerTimeStampString -replace '\s.*$') -match $Today
                    $TimeStampString = $PastLater.TimeStamp.ForEach( { $_.ToString() })
                    $RequestsToday = ($TimeStampString -replace '\s.*$') -match $Today

                    if (([array]$RequestsToday).Count -gt ($Policy.TimesDay * $Policy.Computer)) {
                        $ErrorNotification = 'No more requests allowed for {0} today.' -f $User.ObjectGUID.Guid
                        $Request | Add-Member -MemberType NoteProperty -Name Error -Value $ErrorNotification -ErrorAction Stop
                        $Request | Write-DbaDbTableData -SqlInstance localhost -Database Later -Table FailedRequests -ErrorAction Stop
                        throw [System.AccessViolationException]::New($ErrorNotification -replace ($User.ObjectGUID.Guid, $User.Name))
                    }
                    elseif (([array]$CurrentComputerRequestsToday).Count -gt $Policy.TimesDay) {
                        $ErrorNotification = 'No more requests allowed for computer name {0} for user {1} today.' -f $ComputerName, $User.ObjectGUID.Guid
                        $Request | Add-Member -MemberType NoteProperty -Name Error -Value $ErrorNotification -ErrorAction Stop
                        $Request | Write-DbaDbTableData -SqlInstance localhost -Database Later -Table FailedRequests -ErrorAction Stop
                        throw [System.AccessViolationException]::New($ErrorNotification -replace ($User.ObjectGUID.Guid, $User.Name))
                    }
                    elseif (([array]$PastLater.ComputerName | Sort-Object -Unique).Count -gt $Policy.Computer) {
                        $ErrorNotification = 'User {0} only permitted to request for {1} computers. Limit reached, contact support.' -f $User.ObjectGUID.Guid, $Policy.Computer
                        $Request | Add-Member -MemberType NoteProperty -Name Error -Value $ErrorNotification -ErrorAction Stop
                        $Request | Write-DbaDbTableData -SqlInstance localhost -Database Later -Table FailedRequests -ErrorAction Stop
                        throw [System.AccessViolationException]::New($ErrorNotification -replace ($User.ObjectGUID.Guid, $User.Name))
                    }
                    elseif ($CurrentComputerPastLater.Timestamp[0] -ge $Now.AddHours(-1)) {
                        $ErrorNotification = 'Request already submitted for {0}, wait time {1} Minutes.' -f $User.ObjectGUID.Guid, ($PastLater[0].Timestamp - $Now.AddHours(-1)).Minutes
                        $Request | Add-Member -MemberType NoteProperty -Name Error -Value $ErrorNotification -ErrorAction Stop
                        $Request | Write-DbaDbTableData -SqlInstance localhost -Database Later -Table FailedRequests -ErrorAction Stop
                        throw [System.AccessViolationException]::New($ErrorNotification -replace ($User.ObjectGUID.Guid, $User.Name))
                    }
                }
                try {
                    Get-AdmPwdPassword -ComputerName $ComputerName -ErrorAction Stop
                    $Request | Write-DbaDbTableData -SqlInstance localhost -Database Later -Table Requests -ErrorAction Stop
                }
                catch {
                    $ErrorNotification = 'Unknown error: {0}' -f $_.Exception.Message
                    $Request | Add-Member -MemberType NoteProperty -Name Error -Value $ErrorNotification -ErrorAction Stop
                    $Request | Write-DbaDbTableData -SqlInstance localhost -Database Later -Table FailedRequests -ErrorAction Stop
                    throw [System.SystemException]::New($ErrorNotification)
                }
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}