# function ConfigurePageFile {
#     Param(
#         [Parameter(Mandatory = $True)] [String]   $fdqn
#     )

#     $PageFileLocation = 'F:\'
#     $PageFileSize = 8192
#     $PageFileSettings = Get-DbaPageFileSetting -ComputerName $fdqn
#     if ( $PageFileSettings.FileName -notlike "$PageFileLocation*" -or $PageFileSettings.InitialSize -ne $PageFileSize  -or $PageFileSettings.MaximumSize -ne $PageFileSize  ){
#         Write-Verbose "Setting page file size"
#         Set-PageFile -ComputerName $fdqn -Location $PageFileLocation -InitialSize $PageFileSize -MaximumSize $PageFileSize        
#     }
#     else{
#         Write-Output "Page file in desired state"
#         $PageFileSettings
#     }
# }

function AddSqlManagementToLocalAdmin {
    Param(
        [Parameter(Mandatory = $True)] [String]   $fdqn
    )

    #Add "SQL Management Group to local administrators, this is for CommVault access to the server"
    $group = $null
    try {
        $group = Invoke-Command -ComputerName $fdqn -ScriptBlock { Get-LocalGroupMember -Group "Administrators" -Member $using:SQLManagement }  -ErrorAction Ignore
    }
    catch {
    }

    try {
        if ($null -eq $group -or ($group.Name -notcontains $SQLManagement)) {
            Write-Verbose "Adding $($group.Name) to Local Adminstrators group on $servername"
            Invoke-Command -ComputerName $fdqn -ScriptBlock { Add-LocalGroupMember -Group "Administrators" -Member $using:SQLManagement }
        }
        else {
            Write-Verbose "$($group.Name) found on $fdqn in Local Adminstrators group"
        }
    }
    catch {
        Write-Error "Error adding SQL Management to local administrators: $_" 
    }

    try{
        New-DbaLogin -SqlInstance "$fdqn\$InstanceName" -Login $SQLManagement -WarningAction SilentlyContinue
        Set-DbaLogin -SqlInstance "$fdqn\$InstanceName" -Login $SQLManagement -AddRole sysadmin
    }
    catch{
        Write-Error "Error creating the login for $SQLManagement and adding it to the sysadmin server role: $_"
    }
}

function DisableSaLogin {
    Param(
        [Parameter(Mandatory = $True)]  [String] $fdqn,
        [String] $InstanceName = "MSSQLSERVER"
    )

    #Disable the sa login.
    Get-DbaLogin -SqlInstance "$fdqn\$InstanceName" | Where-Object { $_.Name -eq 'sa' } | Set-DbaLogin -Disable
}

function ConfigureTraceFlags {
    Param(
        [Parameter(Mandatory = $True)]    [String]   $fdqn,
        [String]   $InstanceName = "MSSQLSERVER"
    )

    $TraceFlags = @(3226)
    if ($SqlVersion -lt 2016 ) {
        $TraceFlags += 1117
        $TraceFlags += 1118
    }
    Write-Verbose "Enabling trace flags $TraceFlags"
    
    try {
        Enable-DbaTraceFlag -SqlInstance "$fdqn\$InstanceName" -TraceFlag $TraceFlags -WarningAction SilentlyContinue
        Set-DbaStartupParameter -SqlInstance "$fdqn\$InstanceName" -TraceFlag $TraceFlags -Confirm:$false
    }
    catch {
        Write-Error "Error enabling or setting the instance trace flags: $_"
    }
}

function SetSpConfigureOptions {
    Param(
        [Parameter(Mandatory = $True)]    [String]   $fdqn,
        [String]   $InstanceName = "MSSQLSERVER"
    )
  
    if ( (Get-DbaSpConfigure -SqlInstance "$fdqn\$InstanceName" -Name 'remote admin connections').ConfiguredValue -ne 1) {
        Set-DbaSpConfigure  -SqlInstance "$fdqn\$InstanceName"  -Name 'remote admin connections' -Value 1 
    }

    if ( (Get-DbaSpConfigure -SqlInstance "$fdqn\$InstanceName" -Name 'optimize for ad hoc workloads').ConfiguredValue -ne 1) {
        Set-DbaSpConfigure   -SqlInstance "$fdqn\$InstanceName" -Name 'optimize for ad hoc workloads' -Value 1 
    }

    if ( (Get-DbaSpConfigure -SqlInstance "$fdqn\$InstanceName" -Name 'Database Mail XPs').ConfiguredValue -ne 1) {
        Set-DbaSpConfigure   -SqlInstance "$fdqn\$InstanceName" -Name 'Database Mail XPs' -Value 1 
    }

    #Set CTFP to initial value of 50
    Set-DbaSpConfigure -SqlInstance "$fdqn\$InstanceName"  -Name 'cost threshold for parallelism' -Value 50 -WarningAction SilentlyContinue
}

function ConfigureModelDatabase  {
    Param(
        [Parameter(Mandatory = $True)]    [String]   $fdqn,
        [String]   $InstanceName = "MSSQLSERVER"
    )

    try {
        $modelrecoverymodel = Get-DbaDbRecoveryModel -SqlInstance "$fdqn\$InstanceName" -Database "MODEL"
        if ( $modelrecoverymodel.RecoveryModel -ne 'SIMPLE' ){
            Set-DbaDbRecoveryModel -SqlInstance "$fdqn\$InstanceName" -Database "MODEL" -RecoveryModel Simple -Confirm:$false -EnableException
        }
        $Query = "ALTER DATABASE [model] MODIFY FILE ( NAME = N`'modeldev`', FILEGROWTH = 512MB )"
        Invoke-DbaQuery -SqlInstance "$fdqn\$InstanceName" -Query $Query -EnableException
        $Query = "ALTER DATABASE [model] MODIFY FILE ( NAME = N`'modellog`', FILEGROWTH = 512MB )"
        Invoke-DbaQuery -SqlInstance "$fdqn\$InstanceName" -Query $Query -EnableException

        #Invoke-DbaQuery -SqlInstance "$fdqn\$InstanceName" -Database "MASTER" -File "$folder\2-querystore.sql" -EnableException
        

        #Set-DbaDbQueryStoreOption -SqlInstance "$fdqn\$InstanceName" -Database 'MODEL' -State ReadWrite -FlushInterval 900 -CollectionInterval 30 -MaxSize 1000 -CaptureMode Auto -CleanupMode Auto -StaleQueryThreshold 367
    }
    catch {
        Write-Error "Error configuring the model database: $_"
    }
}

function ConfigureSqlMail{
    Param(
        [Parameter(Mandatory = $True)]    [String]   $fdqn,
        [String]   $InstanceName = "MSSQLSERVER"
    )

    try{
        # $mailaccount = Get-DbaDbMailAccount -SqlInstance "$fdqn\$InstanceName"
        # if ( $mailaccount.name -ne 'Alerts'){
        #     New-DbaDbMailAccount -SqlInstance "$fdqn\$InstanceName" -Name 'Alerts' -EmailAddress akoba101@gmail.com -MailServer smtp.gmail.com -force
        #     New-DbaDbMailProfile -SqlInstance "$fdqn\$InstanceName" -Name 'Alerts' -MailAccountName 'Alerts' -MailAccountPriority 1
        # }
        $Query = Get-Content -Path emailquery.sql -Raw
        $script = Invoke-Sqlcmd -Query $Query -ServerInstance $fdqn
    }
    catch{
        Write-Error "Error configuring SQL Database Mail Account: $_"
    }
}

function ConfigureSqlAgent {
    Param(
        [Parameter(Mandatory = $True)]    [String]   $fdqn,
        [String]   $InstanceName = "MSSQLSERVER"
    )

    try {
        Set-DbaAgentServer -SqlInstance "$fdqn\$InstanceName" -MaximumHistoryRows 10000 -MaximumJobHistoryRows 1000 -AgentMailType DatabaseMail -DatabaseMailProfile 'Notifications' -SaveInSentFolder Enabled
    }
    catch {
        Write-Error "Error configuring the SQL Agent: $_"
    }
}

function Invoke-SqlConfigure {
    Param(
        [Parameter(Mandatory = $True)]    [String]   $fdqn,
        [String]   $InstanceName = "MSSQLSERVER"
    )

    Set-DbaPowerPlan -ComputerName $fdqn -PowerPlan 'High Performance'
    
    Set-DbaMaxDop -SqlInstance "$fdqn\$InstanceName"

    Set-DbaMaxMemory -SqlInstance "$fdqn\$InstanceName"

    Set-DbaTempdbConfig -SqlInstance "$fdqn\$InstanceName" -DataFileSize 1024 -DataFileGrowth 1024 -LogFileSize 1024 -LogFileGrowth 1024 -DataPath 'T:\TEMPDB' -LogPath 'L:\LOGS' 

    Install-DbaMaintenanceSolution -SqlInstance "$fdqn\$InstanceName" -LogToTable -InstallJobs

    Install-DbaWhoIsActive -SqlInstance "$fdqn\$InstanceName" -Database 'master'

    DisableSaLogin -fdqn $fdqn -InstanceName $InstanceName
    
    ConfigureTraceFlags -fdqn $fdqn -InstanceName $InstanceName
    
    SetSpConfigureOptions -fdqn $fdqn -InstanceName $InstanceName
  
    ConfigureModelDatabase -fdqn $fdqn -InstanceName $InstanceName

    ConfigureSqlMail -fdqn $fdqn -InstanceName $InstanceName

    ConfigureSqlAgent -fdqn $fdqn -InstanceName $InstanceName
}
