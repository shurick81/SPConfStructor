#following resources are to be installed on the SQL Node
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name xPSDesiredStateConfiguration -Force
Install-Module -Name xSystemSecurity -Force
Install-Module -Name xDSCDomainJoin -Force
Install-Module -Name xNetworking -Force
Install-Module -Name xStorage -Force
Install-Module -Name xSQLServer -Force

