function Invoke-SQL {
    <#
    .SYNOPSIS
    Used to query a database using ADO .Net

    .DESCRIPTION
    Used to query a database using ADO .Net

    .EXAMPLE
    Invoke-SQL -dataSource $SqlInstance -Database $Database -sqlCommand $PolicySQLQuery

    #>
    param(
        [string] $dataSource = ".\SQLEXPRESS",
        [string] $database = "MasterData",
        [string] $sqlCommand = $(throw "Please specify a query.")
      )

    $connectionString = "Data Source=$dataSource; " +
            "Integrated Security=SSPI; " +
            "Initial Catalog=$database"

    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()

    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null

    $connection.Close()
    $dataSet.Tables

}

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
        $InsertTableRequests = @"
INSERT INTO [$Database].[$Schema].[$TableRequests](UserId,ComputerName,ComputerNameByAddress,ComputerIPAddress,ComputerNameMatchAddress,Timestamp)
	VALUES ('{0}','{1}','{2}','{3}','{4}','{5}')
"@

        $InsertTableFailedRequests = @"
INSERT INTO [$Database].[$Schema].[$TableFailedRequests](UserId,ComputerName,ComputerNameByAddress,ComputerIPAddress,ComputerNameMatchAddress,Error,Timestamp)
	VALUES ('{0}','{1}','{2}','{3}','{4}','{5}','{6}')
"@ 
    }
    process {
        if ($PSCmdlet.ShouldProcess($ComputerName)) {
            try {
                $Request = Get-LaterRequesterInfo -ComputerName $ComputerName -ErrorAction Stop

                $PolicySQLQuery = $BasePolicyQuery -replace 'REPLACESID', ("'{0}'" -f ($Request.UserPolicyGroups -join "', '"))
                try {
                    [Object[]]$Policies = Invoke-SQL -dataSource $SqlInstance -Database $Database -sqlCommand $PolicySQLQuery -ErrorAction Stop | Sort-Object -Property Computers
                    $Policy = $Policies[0]
                    # Preferably log that the user has more than one policy if ($Policies.Count -gt 1)
                }
                catch {
                    throw [System.AccessViolationException]::New('No L.A.T.E.R policy found for user.')
                }

                $PastLaterSQLQuery = $BasePastLaterQuery -replace 'REPLACESID', $Request.UserId
                [Object[]]$PastLater = Invoke-SQL -dataSource $SqlInstance -Database $Database -sqlCommand $PastLaterSQLQuery -ErrorAction Stop

                $Request.psobject.Properties.Remove('UserPolicyGroups')
                $Now = [datetime]::Now
                if ($null -ne $PastLater) {
                    $ThrottleReached = $false
                    $CurrentComputerPastLater = $PastLater | Where-Object { $_.ComputerName -eq $ComputerName }
                    $CurrentComputerTimeStampString = $CurrentComputerPastLater.TimeStamp.ForEach( { $_.ToString() })
                    $CurrentComputerRequestsToday = ($CurrentComputerTimeStampString -replace '\s.*$') -match $Today
                    $TimeStampString = $PastLater.TimeStamp.ForEach( { $_.ToString() })
                    $RequestsToday = ($TimeStampString -replace '\s.*$') -match $Today
                    $ComputersRequested = ([array]$PastLater.ComputerName | Sort-Object -Unique).Count

                    if (([array]$RequestsToday).Count -ge ($Policy.TimesPerDay * $Policy.Computers)) {
                        $ThrottleReached = $true
                        $ErrorNotification = 'No more requests allowed for {0} today.' -f $Request.UserId
                    }
                    elseif (([array]$CurrentComputerRequestsToday).Count -ge $Policy.TimesPerDay) {
                        $ThrottleReached = $true
                        $ErrorNotification = 'No more requests allowed for user {0} on computer name {1} today.' -f $Request.UserId, $ComputerName
                    }
                    elseif ($ComputersRequested -eq 1 -and $ComputerName -notin $PastLater.ComputerName) {
                        $ThrottleReached = $true
                        $ErrorNotification = 'User {0} only permitted to request for this computer {1}. Limit reached, contact support.' -f $Request.UserId, $PastLater.ComputerName
                    }
                    elseif ($ComputersRequested -ne 1 -and $ComputersRequested -ge $Policy.Computers) {
                        $ThrottleReached = $true
                        $ErrorNotification = 'User {0} only permitted to request for {1} computers. Limit reached, contact support.' -f $Request.UserId, $Policy.Computers
                    }
                    elseif (([array]$CurrentComputerRequestsToday).Count -gt 0) {
                        if (($CurrentComputerPastLater.Timestamp)[0] -ge $Now.AddHours(-1)) {
                            $ThrottleReached = $true
                            $ErrorNotification = 'Request already submitted for {0}, wait time {1} Minutes.' -f $Request.UserId, ($PastLater[0].Timestamp - $Now.AddHours(-1)).Minutes
                        }
                    }
                    if ($ThrottleReached) {
                        $Request | Add-Member -MemberType NoteProperty -Name Error -Value $ErrorNotification -ErrorAction Stop
                        $InsertTableFailedRequestsValues = $InsertTableFailedRequests -f $Request.UserId,$Request.ComputerName,$Request.ComputerNameByAddress,$Request.ComputerIPAddress,$Request.ComputerNameMatchAddress,$Request.Error,$Now
                        Invoke-SQL -dataSource $SqlInstance -Database $Database -sqlCommand $InsertTableFailedRequestsValues -ErrorAction Stop
                        throw [System.AccessViolationException]::New($ErrorNotification -replace ($Request.UserId, ($PSSenderInfo.ConnectedUser -replace '^(?:.+\\)')))
                    }
                }
                try {
                    Get-AdmPwdPassword -ComputerName $ComputerName -ErrorAction Stop
                    $InsertTableRequestsValues = $InsertTableRequests -f $Request.UserId,$Request.ComputerName,$Request.ComputerNameByAddress,$Request.ComputerIPAddress,$Request.ComputerNameMatchAddress,$Now
                    Invoke-SQL -dataSource $SqlInstance -Database $Database -sqlCommand $InsertTableRequestsValues -ErrorAction Stop
                }
                catch {
                    $ErrorNotification = 'Unknown error: {0}' -f $_.Exception.Message
                    $Request | Add-Member -MemberType NoteProperty -Name Error -Value $ErrorNotification -ErrorAction Stop
                    $InsertTableFailedRequestsValues = $InsertTableFailedRequests -f $Request.UserId,$Request.ComputerName,$Request.ComputerNameByAddress,$Request.ComputerIPAddress,$Request.ComputerNameMatchAddress,$Request.Error,$Now
                    Invoke-SQL -dataSource $SqlInstance -Database $Database -sqlCommand $InsertTableFailedRequestsValues -ErrorAction Stop
                    throw [System.SystemException]::New($ErrorNotification)
                }
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}