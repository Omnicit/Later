function Get-LaterRequesterInfo {
    [CmdletBinding(
        SupportsShouldProcess
    )]
    param (
        # Input a valid Computer Name.
        [Parameter(
            Mandatory
        )]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )
    process {
        if ($PSCmdlet.ShouldProcess($ComputerName)) {
            $WSManInstance = Get-WSManInstance -ConnectionURI $PSSenderInfo.ConnectionString -ResourceURI shell -Enumerate -ErrorAction Stop
            try {
                $ComputerNameByAddress = ([System.Net.Dns]::GetHostByAddress($WSManInstance.ClientIP).HostName)
                if ($ComputerNameByAddress -match $ComputerName) {
                    $AddressMatchName = $true
                }
                else {
                    $AddressMatchName = $false
                }
            }
            catch {
                $ComputerNameByAddress = 'NULL'
                $AddressMatchName = $false
            }
            $UserPolicyGroups = foreach ($Claim in $PSSenderInfo.UserInfo.WindowsIdentity.UserClaims) {
                try {
                    if ([Security.Principal.SecurityIdentifier]::new($Claim.Value).Translate([Security.Principal.NTAccount]).Value |
                        Where-Object -FilterScript { $_ -match '^(?:.+\\)(res-sys-later\s(pol\d+|requester)$)' }) {
                        $Claim.Value
                    }
                }
                catch {
                    continue
                }
            }
            [PSCustomObject]@{
                UserId                   = $PSSenderInfo.UserInfo.WindowsIdentity.User.Value
                ComputerName             = $ComputerName
                ComputerNameByAddress    = $ComputerNameByAddress
                ComputerIPAddress        = $WSManInstance.ClientIP
                ComputerNameMatchAddress = $AddressMatchName
                UserPolicyGroups         = $UserPolicyGroups
            }
        }
    }
}