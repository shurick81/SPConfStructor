#you need this for compiling mofs on your development machine
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Install-Module -Name AzureRm.Resources -RequiredVersion 4.3.1 -Force
Install-Module -Name AzureRm.Network -RequiredVersion 4.3.1 -Force
Install-Module -Name AzureRM.Storage -RequiredVersion 3.3.1 -Force
Install-Module -Name AzureRM.Compute -RequiredVersion 3.3.1 -Force

Install-Module -Name xRemoteDesktopAdmin -Force
Install-Module -Name xPSDesiredStateConfiguration -Force
Install-Module -Name xActiveDirectory -Force
Install-Module -Name xSystemSecurity -Force
Install-Module -Name xDSCDomainJoin -Force
Install-Module -Name xNetworking -Force
Install-Module -Name xStorage -Force
Install-Module -Name cAzureStorage -Force
Install-Module -Name xSQLServer -Force
Install-Module -Name xPendingReboot -Force
Install-Module -Name xWindowsUpdate -Force
Install-Module -Name xCredSSP -Force
Install-Module -Name SharePointDSC -Force
Install-Module -Name xWebAdministration -Force
