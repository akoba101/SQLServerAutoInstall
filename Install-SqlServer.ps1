Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# Install-Module -Name Pester -Force -SkipPublisherCheck
# Install-Module -Name dbatools -Force -SkipPublisherCheck

#region Dot sourcing of functions
$Environment = 'LAB'
. .\Import-EnvironmentSettings.ps1 -DataCenter $Environment
. .\Test-AdCredential.ps1
. .\Invoke-SqlConfigure.ps1
#endregion

#region Installation Variables
$Version = 2022
$PCName = 'DBSQL1'
$fdqn = [System.Net.Dns]::GetHostByName($PCName).HostName
$Features = @('ENGINE')

$ServiceAccount = "dbsqlsvc"
$svcPassword = ConvertTo-SecureString -String 'passwordfordbsqlsvc' -AsPlainText -Force
$EngineCredential = $AgentCredential = New-Object System.Management.Automation.PSCredential("$ActiveDirectoryDomain\$ServiceAccount", $svcPassword)
$InstallationCredential = Get-Credential -UserName "$env:USERDOMAIN\$env:USERNAME" -Message 'Enter your credential information...'



$path = ".\Test-PreInstallationChecks.ps1"
$parameters = @{
    fdqn = $fdqn;  
    EngineCredential = $EngineCredential; 
    AgentCredential = $AgentCredential; 
    InstallationCredential = $InstallationCredential; 
    InstallationSource =  $InstallationSources[$Version];
    UpdateSource =  $UpdateSources[$Version];
}

$container = New-PesterContainer -Path $path -Data $parameters

$PreflightChecksResult = Invoke-Pester -Container $container 


if ( $PreflightChecksResult.FailedCount -gt 0 ){
    Write-Output "FAILED: Preflight checks failed please ensure pester test passes" -ErrorAction Stop
}
#endregion

#region Installation Execution
$Configuration = @{ UpdateSource = $UpdateSources[$Version]; BROWSERSVCSTARTUPTYPE = "Automatic"}

$InstallationParameters = @{
    SqlInstance = $PCName 
    Path = $InstallationSources[$Version]
    Version = $Version
    Feature = $Features
    InstancePath = $InstancePath
    DataPath = $DataPath
    LogPath = $LogPath
    TempPath = $TempPath
    BackupPath = $BackupPath
    EngineCredential = $EngineCredential
    AgentCredential = $AgentCredential
    Credential = $InstallationCredential
    Configuration = $Configuration
    PerformVolumeMaintenanceTasks = $true
    Restart = $true
    Confirm = $false 
    Verbose = $true
}

$InstallationResult = Install-DbaInstance @InstallationParameters
$InstallationResult

if ( -Not ($InstallationResult.Successful )){
    Write-Output "FAILED: Installation on $fdqn failed. Examine the installation log at $($InstallationResult.LogFile) on the target server." -ErrorAction Stop
}
#endregion

#Check for SSL encryption
$script = Invoke-Sqlcmd -Query "SELECT DISTINCT encrypt_option 
FROM sys.dm_exec_connections WHERE session_id = @@SPID" -ServerInstance $fdqn

if ( -Not ($script.encrypt_option -eq 'True')){
    Write-Output "FAILED: SSL encryption on  $fdqn failed." -ErrorAction Stop
}
#endregion

# Configure SQL instance
Invoke-SqlConfigure -fdqn $fdqn 


# Test SQL install
#Invoke-Pester -Script @{ Path = '.\Test-PostInstallationChecks.ps1' ; Parameters = @{ fdqn = $fdqn; } }


