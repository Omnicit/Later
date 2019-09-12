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
        $InsertTablePasswordResets = @"
INSERT INTO [$Database].[$Schema].[$TablePasswordResets](UserId,Status,ComputerName,ComputerNameByAddress,ComputerIPAddress,ComputerNameMatchAddress,Timestamp)
VALUES ('{0}','{1}','{2}','{3}','{4}','{5}','{6}')
"@ 
        if ($PSCmdlet.ShouldProcess($ComputerName)) {
            try {
                $Request = Get-LaterRequesterInfo -ComputerName $ComputerName -ErrorAction Stop
                $Request.psobject.Properties.Remove('UserPolicyGroups')

                $Now = [datetime]::Now
                $Reset = Reset-AdmPwdPassword -ComputerName $ComputerName -ErrorAction Stop
                $Request | Add-Member -MemberType NoteProperty -Name Status -Value $Reset.Status -ErrorAction Stop
                $InsertTablePasswordResetsValues = $InsertTablePasswordResets -f $Request.UserId,$Request.Status,$Request.ComputerName,$Request.ComputerNameByAddress,$Request.ComputerIPAddress,$Request.ComputerNameMatchAddress,$Now
                Invoke-SQL -dataSource $SqlInstance -Database $Database -sqlCommand $InsertTablePasswordResetsValues -ErrorAction Stop
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}