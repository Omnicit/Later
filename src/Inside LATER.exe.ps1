$buttonRequestAdministrator_Click = {
    $Session = New-PSSession -ComputerName ZPSQL01 -ConfigurationName Requester -Name Requester
    $null = Import-PSSession -Session $Session -AllowClobber -DisableNameChecking
	
    $Later = Get-CurrentComputerLATER -ComputerName $env:COMPUTERNAME
	
    # Update Group Policy to allow for 90 -+ 30 minutes of administrator time.
    $null = gpupdate /force
	
    $Cred = [pscredential]::new('Administrator', (ConvertTo-SecureString -String $Later.Password -AsPlainText -Force))
    Start-Process -FilePath PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command Add-LocalGroupMember -Group Administrators -Member 'NT Authority\Interactive'" -Credential $Cred
    Remove-PSSession -Session $Session -Confirm:$false
	
    # Update password for Administrator
    Update-CurrentComputerLATERPassword -ComputerName $env:COMPUTERNAME
	
    # Verify
    $Members = Get-LocalGroupMember -Group Administrators
    if ($Members.Name -contains 'NT AUTHORITY\INTERACTIVE') {
        # Success
        $richtextbox2.Visible = $true
    }
    else {
        # Error
        $richtextbox3.Visible = $true
    }
}