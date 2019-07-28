$buttonRequestAdministrator_Click = {
    $LATERServer = 'ZPSQL01.contoso.com'
    try {
        try {
            $progressbaroverlay1.Visible = $true
            $Session = New-PSSession -ComputerName $LATERServer -ConfigurationName LATER
            $progressbaroverlay1.Value = 10

            $Later = Invoke-Command -Session $Session -ScriptBlock { Get-CurrentComputerLATER -ComputerName $using:env:COMPUTERNAME }
            $progressbaroverlay1.Value = 20

            # Update Group Policy to allow for 90 (with +- 30 minutes offset time) of administrator time.
            $null = gpupdate.exe /force
            $progressbaroverlay1.Value = 30

            $Cred = [pscredential]::new('Administrator', (ConvertTo-SecureString -String $Later.Password -AsPlainText -Force))
            $progressbaroverlay1.Value = 40
            Start-Process -FilePath PowerShell.exe -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command Add-LocalGroupMember -Group Administrators -Member 'NT Authority\Interactive'" -Credential $Cred
            $progressbaroverlay1.Value = 50

            # Update password for Administrator to avoid reuse
            $Later = Invoke-Command -Session $Session -ScriptBlock { Reset-CurrentComputerLATERPassword -ComputerName $using:env:COMPUTERNAME }
            $progressbaroverlay1.Value = 60

            Remove-PSSession -Session $Session -Confirm:$false
            $progressbaroverlay1.Value = 70

            # Verify LATER
            try {
                Start-Sleep -Seconds 1 # Sleep for 1 second because of slow enumeration for local group members.
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