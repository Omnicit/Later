$buttonRequestAdministrator_Click = {
    # Server configured with the JEA instance
    $LATERServer = 'ZPSQL01.contoso.com'
    try {
        try {
            $progressbaroverlay1.Visible = $true
            $SessionOption = New-PSSessionOption -IdleTimeout 60000
            $Session = New-PSSession -ComputerName $LATERServer -ConfigurationName LATER -SessionOption $SessionOption
            $progressbaroverlay1.Value = 10

            # Retrive the current LAPS password for $Env:ComputerName using Invoke-Command. Enter-PSSession and Import-PSSession is unavailable because of the JEA Configuration.
            $Later = Invoke-Command -Session $Session -ScriptBlock { Get-CurrentComputerLATER -ComputerName $using:env:COMPUTERNAME }
            $progressbaroverlay1.Value = 20

            # Update Group Policy to allow for 90 (with +- 30 minutes offset time) of administrator time.
            $null = gpupdate.exe /force
            $progressbaroverlay1.Value = 30

            <#
            As encoded command
            Add-LocalGroupMember -Group Administrators -Member 'NT Authority\Interactive';
            Add-Type -AssemblyName System.Web;
            Set-LocalUser -Name Administrator -Password $Random ([System.Web.Security.Membership]::GeneratePassword(24, 5) | ConvertTo-SecureString -AsPlainText -Force)
            #>
            $Command = 'QQBkAGQALQBMAG8AYwBhAGwARwByAG8AdQBwAE0AZQBtAGIAZQByACAALQBHAHIAbwB1AHAAIABBAGQAbQBpAG4AaQBzAHQAcgBhAHQAbwByAHMAIAAtAE0AZQBtAGIAZQByACAAJwBOAFQAIABBAHUAdABoAG8AcgBpAHQAeQBcAEkAbgB0AGUAcgBhAGMAdABpAHYAZQAnADsADQAKAEEAZABkAC0AVAB5AHAAZQAgAC0AQQBzAHMAZQBtAGIAbAB5AE4AYQBtAGUAIABTAHkAcwB0AGUAbQAuAFcAZQBiADsADQAKAFMAZQB0AC0ATABvAGMAYQBsAFUAcwBlAHIAIAAtAE4AYQBtAGUAIABBAGQAbQBpAG4AaQBzAHQAcgBhAHQAbwByACAALQBQAGEAcwBzAHcAbwByAGQAIAAoAFsAUwB5AHMAdABlAG0ALgBXAGUAYgAuAFMAZQBjAHUAcgBpAHQAeQAuAE0AZQBtAGIAZQByAHMAaABpAHAAXQA6ADoARwBlAG4AZQByAGEAdABlAFAAYQBzAHMAdwBvAHIAZAAoADIANAAsACAANQApACAAfAAgAEMAbwBuAHYAZQByAHQAVABvAC0AUwBlAGMAdQByAGUAUwB0AHIAaQBuAGcAIAAtAEEAcwBQAGwAYQBpAG4AVABlAHgAdAAgAC0ARgBvAHIAYwBlACkA'
            $Cred = [pscredential]::new('Administrator', (ConvertTo-SecureString -String $Later.Password -AsPlainText -Force))
            $progressbaroverlay1.Value = 40
            Start-Process -FilePath PowerShell.exe -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $Command" -Credential $Cred
            $progressbaroverlay1.Value = 50

            # Update password for LAPS to avoid reuse, will be applied after next gpupdate.
            $Later = Invoke-Command -Session $Session -ScriptBlock { Reset-CurrentComputerLATER -ComputerName $using:env:COMPUTERNAME }
            $progressbaroverlay1.Value = 60

            Remove-PSSession -Session $Session -Confirm:$false
            $progressbaroverlay1.Value = 70

            # Verify that LATER is correctly applied
            try {
                Start-Sleep -Seconds 1 # Sleep for 1 second because of slow enumeration for local group members after add.
                $Members = Get-LocalGroupMember -Group Administrators
            }
            catch {
                $Members = net.exe LocalGroup Administrators | Select-String 'NT AUTHORITY\\INTERACTIVE' | Select-Object -Property @{ Name = 'Name'; Expression = { $_.Line } }
            }
            $progressbaroverlay1.Value = 80
            if ($Members.Name -contains 'NT AUTHORITY\INTERACTIVE') {
                # Success
                $progressbaroverlay1.Value = 100
                $richtextbox2.Visible = $true
            }
            else {
                throw [System.MissingMemberException]::New('Something went wrong')
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    catch {
        $richtextbox3.Text = ('ERROR: {0}' -f $_.Exception.Message)
        $richtextbox3.Visible = $true
    }
}