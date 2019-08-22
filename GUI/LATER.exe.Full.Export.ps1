﻿#requires -Version 3

<#
    .NOTES
    --------------------------------------------------------------------------------
     Code generated by:  SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.166
     Generated on:       2019-08-22 09:50
     Generated by:       Philip Haglund @OmnicitAB
    --------------------------------------------------------------------------------
    .DESCRIPTION
        GUI script generated by PowerShell Studio 2019
#>


#----------------------------------------------
#region Application Functions
#----------------------------------------------

#endregion Application Functions

#----------------------------------------------
# Generated Form Function
#----------------------------------------------
function Show-LATER_psf {

	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	#endregion Import Assemblies

	#----------------------------------------------
	#region Define SAPIEN Types
	#----------------------------------------------
	try{
		[ProgressBarOverlay] | Out-Null
	}
	catch
	{
		Add-Type -ReferencedAssemblies ('System.Windows.Forms', 'System.Drawing') -TypeDefinition  @"
		using System;
		using System.Windows.Forms;
		using System.Drawing;
        namespace SAPIENTypes
        {
		    public class ProgressBarOverlay : System.Windows.Forms.ProgressBar
	        {
                public ProgressBarOverlay() : base() { SetStyle(ControlStyles.OptimizedDoubleBuffer | ControlStyles.AllPaintingInWmPaint, true); }
	            protected override void WndProc(ref Message m)
	            {
	                base.WndProc(ref m);
	                if (m.Msg == 0x000F)// WM_PAINT
	                {
	                    if (Style != System.Windows.Forms.ProgressBarStyle.Marquee || !string.IsNullOrEmpty(this.Text))
                        {
                            using (Graphics g = this.CreateGraphics())
                            {
                                using (StringFormat stringFormat = new StringFormat(StringFormatFlags.NoWrap))
                                {
                                    stringFormat.Alignment = StringAlignment.Center;
                                    stringFormat.LineAlignment = StringAlignment.Center;
                                    if (!string.IsNullOrEmpty(this.Text))
                                        g.DrawString(this.Text, this.Font, Brushes.Black, this.ClientRectangle, stringFormat);
                                    else
                                    {
                                        int percent = (int)(((double)Value / (double)Maximum) * 100);
                                        g.DrawString(percent.ToString() + "%", this.Font, Brushes.Black, this.ClientRectangle, stringFormat);
                                    }
                                }
                            }
                        }
	                }
	            }

                public string TextOverlay
                {
                    get
                    {
                        return base.Text;
                    }
                    set
                    {
                        base.Text = value;
                        Invalidate();
                    }
                }
	        }
        }
"@ -IgnoreWarnings | Out-Null
	}
	#endregion Define SAPIEN Types

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$formOmnicitRequestAdmini = New-Object 'System.Windows.Forms.Form'
	$progressbaroverlay1 = New-Object 'SAPIENTypes.ProgressBarOverlay'
	$richtextbox2 = New-Object 'System.Windows.Forms.RichTextBox'
	$richtextbox1 = New-Object 'System.Windows.Forms.RichTextBox'
	$buttonRequestAdministrator = New-Object 'System.Windows.Forms.Button'
	$picturebox1 = New-Object 'System.Windows.Forms.PictureBox'
	$richtextbox3 = New-Object 'System.Windows.Forms.RichTextBox'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------

	$formOmnicitRequestAdmini_Load={
		#TODO: Initialize Form Controls here

	}

	#region Control Helper Functions

	#endregion

	$buttonRequestAdministrator_Click = {
		# Server configured with the JEA instance
		$LATERServer = 'ZPSQL01.contoso.com'
		try {
			$progressbaroverlay1.Visible = $true
			try {
				[string[]]$Groups = ((whoami /groups /fo csv | ConvertFrom-Csv -Delimiter ',' -ErrorAction Stop).'Group Name' -match '^(?:.+\\)(res-sys-later\s(pol\d+|requester)$)' -replace '^(?:.+\\)')
				if ($Groups.Count -lt 2) {
					throw [System.Management.Automation.RemoteException]::New('Missing policy groups to request administrator access, contact support.')
				}
				$progressbaroverlay1.Value = 10
			}
			catch {
				throw [System.Management.Automation.RemoteException]::New('Missing policy groups to request administrator access, contact support.')
			}
			try {
				$SessionOption = New-PSSessionOption -IdleTimeout 60000 -ErrorAction Stop
				$Session = New-PSSession -ComputerName $LATERServer -ConfigurationName LATER -SessionOption $SessionOption -ErrorAction Stop
				$progressbaroverlay1.Value = 20
			}
			catch {
				throw [System.AccessViolationException]::New('Unable to connect to request server, contact support.')
			}

			# Retrieve the current LAPS password for $Env:ComputerName using Invoke-Command. Enter-PSSession and Import-PSSession is unavailable because of the JEA Configuration.
			try {
				$Later = Invoke-Command -Session $Session -ScriptBlock {
					Get-CurrentComputerLATER -ComputerName $using:env:COMPUTERNAME -ErrorAction Stop
				} -ErrorAction Stop
				$progressbaroverlay1.Value = 30
			}
			catch [System.Management.Automation.Runspaces.InvalidRunspaceStateException] {
				throw [System.Management.Automation.Runspaces.InvalidRunspaceStateException]::New('Restart the Later application and try again.')
			}
			catch [System.Management.Automation.RemoteException] {
				throw [System.AccessViolationException]::New(($_.Exception.Message -replace '^.*:\s'))
			}
			catch {
				throw [System.InvalidOperationException]::New('Something went wrong, contact support with the current timestamp {0}.' -f ([datetime]::Now.ToString()))
			}

			# Update Group Policy to allow for 90 (with +- 30 minutes offset time) of administrator time.
			$null = 'N' | gpupdate.exe /force
			$progressbaroverlay1.Value = 40

			$Command = 'QQBkAGQALQBMAG8AYwBhAGwARwByAG8AdQBwAE0AZQBtAGIAZQByACAALQBHAHIAbwB1AHAAIABBAGQAbQBpAG4AaQBzAHQAcgBhAHQAbwByAHMAIAAtAE0AZQBtAGIAZQByACAAJwBOAFQAIABBAHUAdABoAG8AcgBpAHQAeQBcAEkAbgB0AGUAcgBhAGMAdABpAHYAZQAnADsADQAKAEEAZABkAC0AVAB5AHAAZQAgAC0AQQBzAHMAZQBtAGIAbAB5AE4AYQBtAGUAIABTAHkAcwB0AGUAbQAuAFcAZQBiADsADQAKAFMAZQB0AC0ATABvAGMAYQBsAFUAcwBlAHIAIAAtAE4AYQBtAGUAIABBAGQAbQBpAG4AaQBzAHQAcgBhAHQAbwByACAALQBQAGEAcwBzAHcAbwByAGQAIAAoAFsAUwB5AHMAdABlAG0ALgBXAGUAYgAuAFMAZQBjAHUAcgBpAHQAeQAuAE0AZQBtAGIAZQByAHMAaABpAHAAXQA6ADoARwBlAG4AZQByAGEAdABlAFAAYQBzAHMAdwBvAHIAZAAoADIANAAsACAANQApACAAfAAgAEMAbwBuAHYAZQByAHQAVABvAC0AUwBlAGMAdQByAGUAUwB0AHIAaQBuAGcAIAAtAEEAcwBQAGwAYQBpAG4AVABlAHgAdAAgAC0ARgBvAHIAYwBlACkA'
			$Cred = [pscredential]::new('Administrator', (ConvertTo-SecureString -String $Later.Password -AsPlainText -Force))
			$progressbaroverlay1.Value = 50
			Start-Process -WindowStyle Hidden -FilePath PowerShell.exe -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $Command" -Credential $Cred
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
						Name    = 'Name'; Expression = {
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
					throw [System.MissingMemberException]::New('Something went wrong.')
				}
				else {
					continue
				}
			}
			until ($Count -eq 5)
		}
		catch {
			$richtextbox3.Text = ('Error: {0}' -f $_.Exception.Message)
			$richtextbox3.Visible = $true
		}
	}
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------

	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formOmnicitRequestAdmini.WindowState = $InitialFormWindowState
	}

	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonRequestAdministrator.remove_Click($buttonRequestAdministrator_Click)
			$formOmnicitRequestAdmini.remove_Load($formOmnicitRequestAdmini_Load)
			$formOmnicitRequestAdmini.remove_Load($Form_StateCorrection_Load)
			$formOmnicitRequestAdmini.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch { Out-Null <# Prevent PSScriptAnalyzer warning #> }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formOmnicitRequestAdmini.SuspendLayout()
	$picturebox1.BeginInit()
	#
	# formOmnicitRequestAdmini
	#
	$formOmnicitRequestAdmini.Controls.Add($progressbaroverlay1)
	$formOmnicitRequestAdmini.Controls.Add($richtextbox2)
	$formOmnicitRequestAdmini.Controls.Add($richtextbox1)
	$formOmnicitRequestAdmini.Controls.Add($buttonRequestAdministrator)
	$formOmnicitRequestAdmini.Controls.Add($picturebox1)
	$formOmnicitRequestAdmini.Controls.Add($richtextbox3)
	$formOmnicitRequestAdmini.AutoScaleDimensions = '6, 13'
	$formOmnicitRequestAdmini.AutoScaleMode = 'Font'
	$formOmnicitRequestAdmini.BackColor = 'White'
	$formOmnicitRequestAdmini.ClientSize = '473, 479'
	$formOmnicitRequestAdmini.ForeColor = 'Black'
	$formOmnicitRequestAdmini.FormBorderStyle = 'Fixed3D'
	#region Binary Data
	$formOmnicitRequestAdmini.Icon = $null
	#endregion
	$formOmnicitRequestAdmini.Name = 'formOmnicitRequestAdmini'
	$formOmnicitRequestAdmini.StartPosition = 'CenterScreen'
	$formOmnicitRequestAdmini.Text = 'Omnicit - Request Administrator'
	$formOmnicitRequestAdmini.add_Load($formOmnicitRequestAdmini_Load)
	#
	# progressbaroverlay1
	#
	$progressbaroverlay1.Font = 'Microsoft Sans Serif, 12.25pt'
	$progressbaroverlay1.ForeColor = 'DeepSkyBlue'
	$progressbaroverlay1.Location = '12, 419'
	$progressbaroverlay1.Name = 'progressbaroverlay1'
	$progressbaroverlay1.Size = '449, 48'
	$progressbaroverlay1.TabIndex = 5
	$progressbaroverlay1.Visible = $False
	#
	# richtextbox2
	#
	$richtextbox2.Anchor = 'Top, Left, Right'
	$richtextbox2.BackColor = 'Window'
	$richtextbox2.BorderStyle = 'None'
	$richtextbox2.Font = 'Microsoft Sans Serif, 15.25pt, style=Bold'
	$richtextbox2.ForeColor = 'Green'
	$richtextbox2.Location = '181, 392'
	$richtextbox2.Name = 'richtextbox2'
	$richtextbox2.ReadOnly = $True
	$richtextbox2.RightToLeft = 'No'
	$richtextbox2.ScrollBars = 'None'
	$richtextbox2.Size = '111, 21'
	$richtextbox2.TabIndex = 3
	$richtextbox2.Text = 'SUCCESS'
	$richtextbox2.Visible = $False
	#
	# richtextbox1
	#
	$richtextbox1.BackColor = 'White'
	$richtextbox1.BorderStyle = 'None'
	$richtextbox1.Font = 'Microsoft Sans Serif, 12.25pt'
	$richtextbox1.Location = '12, 200'
	$richtextbox1.Name = 'richtextbox1'
	$richtextbox1.ScrollBars = 'None'
	$richtextbox1.Size = '449, 127'
	$richtextbox1.TabIndex = 2
	$richtextbox1.Text = ' •  Request administrator privileges for 60 minutes.
 •  All requests will be logged.
 •  Excessive use will be reported.
 •  3 requests per day is allowed by default.

 For more information contact support@contoso.com'
	#
	# buttonRequestAdministrator
	#
	$buttonRequestAdministrator.BackColor = 'White'
	$buttonRequestAdministrator.FlatAppearance.BorderColor = 'DeepSkyBlue'
	$buttonRequestAdministrator.FlatAppearance.MouseDownBackColor = 'Transparent'
	$buttonRequestAdministrator.FlatAppearance.MouseOverBackColor = 'WhiteSmoke'
	$buttonRequestAdministrator.FlatStyle = 'Flat'
	$buttonRequestAdministrator.Font = 'Microsoft Sans Serif, 12.25pt, style=Underline'
	$buttonRequestAdministrator.ForeColor = 'DeepSkyBlue'
	$buttonRequestAdministrator.Location = '12, 419'
	$buttonRequestAdministrator.Name = 'buttonRequestAdministrator'
	$buttonRequestAdministrator.Size = '449, 48'
	$buttonRequestAdministrator.TabIndex = 1
	$buttonRequestAdministrator.Text = 'Request Administrator'
	$buttonRequestAdministrator.UseCompatibleTextRendering = $True
	$buttonRequestAdministrator.UseVisualStyleBackColor = $False
	$buttonRequestAdministrator.add_Click($buttonRequestAdministrator_Click)
	#
	# picturebox1
	#
	#region Binary Data
	$picturebox1.Image = $null
	#endregion
	#region Binary Data
	$picturebox1.InitialImage = $null
	#endregion
	$picturebox1.Location = '12, 12'
	$picturebox1.Name = 'picturebox1'
	$picturebox1.Size = '449, 181'
	$picturebox1.TabIndex = 0
	$picturebox1.TabStop = $False
	#
	# richtextbox3
	#
	$richtextbox3.BackColor = 'Window'
	$richtextbox3.BorderStyle = 'None'
	$richtextbox3.Font = 'Microsoft Sans Serif, 11.25pt, style=Bold'
	$richtextbox3.ForeColor = 'Red'
	$richtextbox3.Location = '12, 333'
	$richtextbox3.Name = 'richtextbox3'
	$richtextbox3.ReadOnly = $True
	$richtextbox3.RightToLeft = 'No'
	$richtextbox3.ScrollBars = 'None'
	$richtextbox3.Size = '449, 80'
	$richtextbox3.TabIndex = 4
	$richtextbox3.Text = 'Error: Contact support@contoso.com.'
	$richtextbox3.Visible = $False
	$picturebox1.EndInit()
	$formOmnicitRequestAdmini.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formOmnicitRequestAdmini.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formOmnicitRequestAdmini.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formOmnicitRequestAdmini.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formOmnicitRequestAdmini.ShowDialog()

} #End Function

#Call the form
Show-LATER_psf | Out-Null