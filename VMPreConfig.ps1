#Scope:
#Configures Windows Server VM for domain join for the purpose of hosting SQL Server
#Ethernet Adapter:
##- Disable automatic IPv4 address
##- Configures custom IPv4 settings
##- Disable IPv6
#Drive Configuration:
##- Bring drives online
##- Initialize disks
##- Create partitions and assigns drive letters for Data/Temp/Log/Backup disks
#Active Directory Domain:
##- Add computer to Active Directory Domain

#Prerequisites:
#- Change computer name
#- Add computer to proper OU and groups in Active Directory

#Network Configuration Variables
$MaskBits = 16 # This means subnet mask = 255.255.0.0
$Gateway = "192.168.1.1"
$Dns = "192.168.2.1"
$IPType = "IPv4"
#Domain Variables
$Username = "username"
$Domain = "domain.tld"
$OUPath = "OU Path" #OU address for SQL server computer objects

#User Inputs
$IP = Read-Host -Prompt "Input IP address for the machine..."
$InstallationCredential = Get-Credential -UserName "$Domain\$Username" -Message 'Enter your credential information...'

# Retrieve the network adapter that you want to configure
$adapter = Get-NetAdapter | ? {$_.Status -eq "up"}
# Remove any existing IP, gateway from our ipv4 adapter
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
 $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
}
If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
 $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
}
 # Configure the IP address and default gateway
$adapter | New-NetIPAddress `
 -AddressFamily $IPType `
 -IPAddress $IP `
 -PrefixLength $MaskBits `
 -DefaultGateway $Gateway
# Configure the DNS client server IP addresses
$adapter | Set-DnsClientServerAddress -ServerAddresses $DNS

#Disables IPv6
Disable-NetAdapterBinding –InterfaceAlias $adapter.name –ComponentID ms_tcpip6

#Initialize Disks
Get-Disk | Where-Object IsOffline -Eq $True | Set-Disk -IsOffline $False
Get-Disk | Where-Object PartitionStyle –Eq 'RAW' | Initialize-Disk -PartitionStyle GPT
New-Partition –DiskNumber 1 -DriveLetter d –UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false -AllocationUnitSize 65536 -NewFileSystemLabel "Data"
New-Partition –DiskNumber 2 -DriveLetter t –UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false -AllocationUnitSize 65536 -NewFileSystemLabel "Temp"
New-Partition –DiskNumber 3 -DriveLetter l –UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false -AllocationUnitSize 65536 -NewFileSystemLabel "Log"
New-Partition –DiskNumber 4 -DriveLetter b –UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false -NewFileSystemLabel "Backup"

#Add computer to domain
Add-Computer -DomainName $domain -OUPath $OUPath -Restart -Credential $InstallationCredential