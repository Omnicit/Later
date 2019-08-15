$buttonRequestAdministrator_Click = {
    # Server configured with the JEA instance
    $LATERServer = 'ZPSQL01.contoso.com'
    try {
        $progressbaroverlay1.Visible = $true
        try {
            [string[]]$Group = ((whoami /groups /fo csv | ConvertFrom-Csv -Delimiter ',' -ErrorAction Stop).'Group Name' -match '^(?:.+\\)(res-sys-later\spol\d+$)' -replace '^(?:.+\\)')
            if ($Group.Count -eq 0) {
                throw [System.Management.Automation.RemoteException]::New('Missing policy groups to request administrator access, contact support.')
            }
            $progressbaroverlay1.Value = 10
        }
        catch {
            throw [System.Management.Automation.RemoteException]::New('Unable to retrieve group membership.')
        }
        try {
            $SessionOption = New-PSSessionOption -IdleTimeout 60000 -ErrorAction Stop
            $Session = New-PSSession -ComputerName $LATERServer -ConfigurationName LATER -SessionOption $SessionOption -ErrorAction Stop
            $progressbaroverlay1.Value = 20
        }
        catch {
            throw [System.AccessViolationException]::New('Unable to connect to request server')
        }

        # Retrieve the current LAPS password for $Env:ComputerName using Invoke-Command. Enter-PSSession and Import-PSSession is unavailable because of the JEA Configuration.
        try {
            $Later = Invoke-Command -Session $Session -ScriptBlock {
                Get-CurrentComputerLATER -ComputerName $using:env:COMPUTERNAME -ErrorAction Stop
            } -ErrorAction Stop
            $progressbaroverlay1.Value = 30
        }
        catch [System.Management.Automation.Runspaces.InvalidRunspaceStateException] {
            throw [System.Management.Automation.Runspaces.InvalidRunspaceStateException]::New('Restart the Later application and try again')
        }
        catch [System.Management.Automation.RemoteException] {
            throw [System.AccessViolationException]::New(($_.Exception.Message -replace '^.*:\s'))
        }
        catch {
            throw [System.InvalidOperationException]::New('Something went wrong, contact administrator with the current timestamp {0}' -f ([datetime]::Now.ToString()))
        }

        # Update Group Policy to allow for 90 (with +- 30 minutes offset time) of administrator time.
        $null = gpupdate.exe /force
        $progressbaroverlay1.Value = 40
        <#
            As encoded command
            Add-LocalGroupMember -Group Administrators -Member 'NT Authority\Interactive';
            Add-Type -AssemblyName System.Web;
            Set-LocalUser -Name Administrator -Password $Random ([System.Web.Security.Membership]::GeneratePassword(24, 5) | ConvertTo-SecureString -AsPlainText -Force)
        #>
        $Command = 'QQBkAGQALQBMAG8AYwBhAGwARwByAG8AdQBwAE0AZQBtAGIAZQByACAALQBHAHIAbwB1AHAAIABBAGQAbQBpAG4AaQBzAHQAcgBhAHQAbwByAHMAIAAtAE0AZQBtAGIAZQByACAAJwBOAFQAIABBAHUAdABoAG8AcgBpAHQAeQBcAEkAbgB0AGUAcgBhAGMAdABpAHYAZQAnADsADQAKAEEAZABkAC0AVAB5AHAAZQAgAC0AQQBzAHMAZQBtAGIAbAB5AE4AYQBtAGUAIABTAHkAcwB0AGUAbQAuAFcAZQBiADsADQAKAFMAZQB0AC0ATABvAGMAYQBsAFUAcwBlAHIAIAAtAE4AYQBtAGUAIABBAGQAbQBpAG4AaQBzAHQAcgBhAHQAbwByACAALQBQAGEAcwBzAHcAbwByAGQAIAAoAFsAUwB5AHMAdABlAG0ALgBXAGUAYgAuAFMAZQBjAHUAcgBpAHQAeQAuAE0AZQBtAGIAZQByAHMAaABpAHAAXQA6ADoARwBlAG4AZQByAGEAdABlAFAAYQBzAHMAdwBvAHIAZAAoADIANAAsACAANQApACAAfAAgAEMAbwBuAHYAZQByAHQAVABvAC0AUwBlAGMAdQByAGUAUwB0AHIAaQBuAGcAIAAtAEEAcwBQAGwAYQBpAG4AVABlAHgAdAAgAC0ARgBvAHIAYwBlACkA'
        $Cred = [pscredential]::new('Administrator', (ConvertTo-SecureString -String $Later.Password -AsPlainText -Force))
        $progressbaroverlay1.Value = 50
        Start-Process -FilePath PowerShell.exe -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $Command" -Credential $Cred
        $progressbaroverlay1.Value = 60

        # Update password for LAPS to avoid reuse, will be applied after next gpupdate.
        $Later = Invoke-Command -Session $Session -ScriptBlock {
            Reset-CurrentComputerLATER -ComputerName $using:env:COMPUTERNAME -ErrorAction SilentlyContinue
        } -ErrorAction SilentlyContinue
        $progressbaroverlay1.Value = 70

        Remove-PSSession -Session $Session -Confirm:$false -ErrorAction SilentlyContinue
        $progressbaroverlay1.Value = 80

        # Verify that LATER is correctly applied
        $Count = 0
        do {
            $Count++
            try {
                Start-Sleep -Seconds 1
                $Members = Get-LocalGroupMember -Group Administrators -ErrorAction Stop
            }
            catch {
                $Members = net.exe LocalGroup Administrators | Select-String 'NT AUTHORITY\\INTERACTIVE' | Select-Object -Property @{
                    Name = 'Name'; Expression = {
                        $_.Line
                    }
                }
            }
            $progressbaroverlay1.Value = 90
            if ($Members.Name -contains 'NT AUTHORITY\INTERACTIVE') {
                # Success
                $progressbaroverlay1.Value = 100
                $richtextbox2.Visible = $true
                break
            }
            elseif ($Count -eq 5) {
                throw [System.MissingMemberException]::New('Something went wrong')
            }
            else {
                continue
            }
        }
        until ($Count -eq 5)
    }
    catch {
        $richtextbox3.Text = ('ERROR: {0}' -f $_.Exception.Message)
        $richtextbox3.Visible = $true
    }
}