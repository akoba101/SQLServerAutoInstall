#Domain information
$ActiveDirectoryDomain = $env:USERDOMAIN
$NumberOfPhysicalCoresPerCPU = 1

#Drive Path Information
$InstancePath = 'C:\Program Files\Microsoft SQL Server'
$DataPath = 'D:\DATA'
$LogPath = 'L:\LOGS'
$TempPath = 'T:\TEMPDB'
$BackupPath = 'B:\BACKUPS'

#Log file 
$logfile = "output.log"


#Location of installation files for each version of SQL Server. Each of these is currently the latest SP we've standardized on.
$InstallRoot = "\\ServerShares\SQLServerInstall"

$InstallationSources = @{
    2012 = "$InstallRoot\SQL Server Installation Files\en_sql_server_2012_enterprise_edition_with_sp_3_x64_dvd_7286819"
    2014 = "$InstallRoot\SQL Server Installation Files\en_sql_server_2014_developer_edition_with_service_pack_3"
    2016 = "$InstallRoot\SQL Server Installation Files\en_sql_server_2016_developer_with_service_pack_2_x64_dvd_12194995"
    2017 = "$InstallRoot\SQL Server Installation Files\en_sql_server_2017_enterprise_x64_dvd_11293666"
    2019 = "$InstallRoot\SQL Server Installation Files\en_sql_server_2019_enterprise_core_x64_dvd_c7d70add"
    2022 = "$InstallRoot\SQL Server Installation Files\SQLServer2022-x64-ENU-Dev"
}

#Location of update sources for each version of SQL Server. Directory should contain the latest CU we've standardized on.
$UpdateSources = @{
    2012 = "$InstallRoot\SQL Server Update Files\2012Updates"
    2014 = "$InstallRoot\SQL Server Update Files\2014Updates"
    2016 = "$InstallRoot\SQL Server Update Files\2016Updates"
    2017 = "$InstallRoot\SQL Server Update Files\2017Updates"  
    2019 = "$InstallRoot\SQL Server Update Files\2019Updates"    
    2022 = "$InstallRoot\SQL Server Update Files\2022Updates"  
}
