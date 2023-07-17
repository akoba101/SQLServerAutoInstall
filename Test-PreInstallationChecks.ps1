[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)] [String] $fdqn,
    [Parameter(Mandatory = $true)] [PSCredential] $EngineCredential,
    [Parameter(Mandatory = $true)] [PSCredential] $AgentCredential,
    [Parameter(Mandatory = $true)] [PSCredential] $InstallationCredential,
    [Parameter(Mandatory = $true)] [String] $InstallationSource,
    [Parameter(Mandatory = $true)] [String] $UpdateSource
)

Describe "Pre-Installation Checks" {

    Context "Server accessible via WinRM" {
                It "The target server should be accessible via WinRM" {
                    $result = Test-NetConnection -ComputerName $fdqn -InformationLevel Quiet -CommonTCPPort WINRM        
                    $result | Should -Be $true -Because "We need to do stuff with WinRM during the installation."        
        }
    }

    Context "Service Account Validation" {
        It "Testing to see if the Engine Service account credential is valid $($EngineCredential.Username): " {
            $CredentialTestResult = Test-AdCredential -Credential $EngineCredential
            $CredentialTestResult | Should -Be "True" -Because "SQL Server Engine requires a valid service account."
        }

        It "Testing to see if the Agent Service account credential is valid $($AgentCredential.Username): " {
            $CredentialTestResult = Test-AdCredential -Credential $AgentCredential
            $CredentialTestResult | Should -Be "True" -Because "SQL Server Agent requires a valid service account."
        }
    }

    Context "Installation Account Validation" {
        It "Testing to see if the installation account credential is valid $($InstallationCredential.Username): " {
            $CredentialTestResult = Test-AdCredential -Credential $InstallationCredential
            $CredentialTestResult | Should -Be "True" -Because "Need a valid installation account to run the installer."
        }
    }
    Context "Testing for the existence of required drives on target"{
        It "Checks for drive C" {
            $DriveLetter = "C"
            $ServerDrives = Invoke-Command -ComputerName $fdqn -ScriptBlock { Get-PSDrive } 
            $result = $ServerDrives.Name.Contains($DriveLetter)
            $result | Should -Be "True" -Because "SQL Server requires a drive $DriveLetter"
        }
    }
    Context "Testing for the existence of required drives on target"{
        It "Checks for drive D" {
            $DriveLetter = "D"
            $ServerDrives = Invoke-Command -ComputerName $fdqn -ScriptBlock { Get-PSDrive } 
            $result = $ServerDrives.Name.Contains($DriveLetter)
            $result | Should -Be "True" -Because "SQL Server requires a drive $DriveLetter"
        }
    }
    Context "Testing for the existence of required drives on target"{
        It "Checks for drive T" {
            $DriveLetter = "T"
            $ServerDrives = Invoke-Command -ComputerName $fdqn -ScriptBlock { Get-PSDrive } 
            $result = $ServerDrives.Name.Contains($DriveLetter)
            $result | Should -Be "True" -Because "SQL Server requires a drive $DriveLetter"
        }
    }
    Context "Testing for the existence of required drives on target"{
        It "Checks for drive L" {
            $DriveLetter = "L"
            $ServerDrives = Invoke-Command -ComputerName $fdqn -ScriptBlock { Get-PSDrive } 
            $result = $ServerDrives.Name.Contains($DriveLetter)
            $result | Should -Be "True" -Because "SQL Server requires a drive $DriveLetter"
        }
    }
    Context "Testing for the existence of required drives on target"{
        It "Checks for drive B" {
            $DriveLetter = "B"
            $ServerDrives = Invoke-Command -ComputerName $fdqn -ScriptBlock { Get-PSDrive } 
            $result = $ServerDrives.Name.Contains($DriveLetter)
            $result | Should -Be "True" -Because "SQL Server requires a drive $DriveLetter"
        }
    }

    Context "Testing for existance of the installation share" {
        It "Testing to see if the installation share exists $InstallationSource" {
            $result = Test-Path -Path $InstallationSource
            $result | Should -Be "True" -Because "The installation share must exist"
        }
    }

    Context "Testing for existance of the Update Sources share" {
        It "Testing to see if the Update Sources share exists $UpdateSource" {
            $result = Test-Path -Path $UpdateSource
            $result | Should -Be "True" -Because "The Update Sources share must exist"
        }
    }
}
