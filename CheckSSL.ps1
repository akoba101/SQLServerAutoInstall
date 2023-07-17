#Simple script to check if SSL connection is enabled on SQL Server

# First part of the script which creates dialog and forms, and hold input in the textbox
#
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
 
$dialog = New-Object System.Windows.Forms.Form 
$dialog.Text = "Enter SQL Server instance name:"
$dialog.Size = New-Object System.Drawing.Size(400,100) 
$dialog.StartPosition = "CenterScreen"
 
$check = New-Object System.Windows.Forms.Button
$check.Location = New-Object System.Drawing.Size(250,20)
$check.Size = New-Object System.Drawing.Size(75,23)
$check.Text = "Check"
$check.Add_Click({$x=$input.Text;$dialog.Close()})
$dialog.Controls.Add($check)
 
$input = New-Object System.Windows.Forms.TextBox 
$input.Location = New-Object System.Drawing.Size(40,20) 
$input.Size = New-Object System.Drawing.Size(200,20) 
$dialog.Controls.Add($input) 
 
$dialog.Add_Shown({$dialog.Activate()})
[void] $dialog.ShowDialog()
 
$x 
 
#Second part of the script, which executes specific SQL statement and passes result in pop-up dialog
#
$script = Invoke-Sqlcmd -Query "SELECT DISTINCT encrypt_option 
FROM sys.dm_exec_connections WHERE session_id = @@SPID" -ServerInstance $input.Text
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup($script.ItemArray,0,"Connection encryption enabled for instance " + $input.Text + ":")