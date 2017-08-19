Configuration SP2013Prepare
{
    param(
        $configParameters
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile
    Import-DSCResource -Module xSystemSecurity -Name xIEEsc
    Import-DscResource -ModuleName xStorage
    Import-DSCResource -ModuleName SharePointDSC
    Import-DscResource -ModuleName xWebAdministration

    $SPMachines = $configParameters.Machines | ? { ( $_.Roles -contains "WFE" ) -or ( $_.Roles -contains "BATCH" ) -or ( $_.Roles -contains "DistributedCache" ) -or ( $_.Roles -contains "SearchQuery" ) -or ( $_.Roles -contains "SearchCrawl" ) } | % { $_.Name }

    Node $SPMachines
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
         
        Registry LoopBackRegistry
        {
            Ensure      = "Present"  # You can also set Ensure to "Absent"
            Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName   = "DisableLoopbackCheck"
            ValueType   = "DWORD"
            ValueData   = "1"
        }

        xIEEsc DisableIEEsc
        {
            IsEnabled   = $false
            UserRole    = "Administrators"
        }
                        
        xRemoteFile SPServerImageFile
        {
            DestinationPath = "C:\Install\SPImage\SharePointServer_x64_en-us.img"
            Uri = "http://care.dlservice.microsoft.com/dl/download/3/D/7/3D713F30-C316-49B8-9CC0-E1BFC34B63A0/SharePointServer_x64_en-us.img"
        }

        xRemoteFile SPServicePackFile
        {
            DestinationPath = "C:\Install\SPServicePack\officeserversp2013-kb2880552-fullfile-x64-en-us.exe"
            Uri = "https://download.microsoft.com/download/7/A/8/7A84E002-6512-4506-A812-CA66FF6766D9/officeserversp2013-kb2880552-fullfile-x64-en-us.exe"
        }

        xMountImage SPServerImageMount
        {
            ImagePath   = 'C:\Install\SPImage\SharePointServer_x64_en-us.img'
            DriveLetter = 'S'
            DependsOn   = @("[xRemoteFile]SPServerImageFile")
        }

        xWaitForVolume WaitForSPServerImageMount
        {
            DriveLetter         = 'S'
            RetryIntervalSec    = 5
            RetryCount          = 10
            DependsOn           = "[xMountImage]SPServerImageMount"
        }

        File SPServerInstallatorDirectory
        {
            Ensure          = "Present"
            Type            = "Directory"
            Recurse         = $true
            SourcePath      = "S:\"
            DestinationPath = "C:\Install\SPExtracted"
            DependsOn       = "[xWaitForVolume]WaitForSPServerImageMount"
        }

        WindowsFeature NetFramework35Core
        {
            Name = "NetFX3"
            Ensure = "Present"
        }

        SPInstallPrereqs SP2016Prereqs
        {
            InstallerPath   = "C:\Install\SPExtracted\Prerequisiteinstaller.exe"
            OnlineMode      = $true
            DependsOn   = "[File]SPServerInstallatorDirectory","[WindowsFeature]NetFramework35Core"
        }
        
        SPInstall InstallSharePoint 
        { 
            Ensure      = "Present"
            BinaryDir   = "C:\Install\SPExtracted"
            ProductKey  = $configParameters.SPProductKey
            DependsOn   = "[SPInstallPrereqs]SP2016Prereqs"
        }

        Package SPServicePack
        {
            Ensure      = "Present"
            Name        = "SPServicePack"
            Path        = "C:\Install\SPServicePack\officeserversp2013-kb2880552-fullfile-x64-en-us.exe"
            Arguments   = "/install /passive /norestart"
            ProductId   = "6ce0f2ad-2643-496c-9b48-d0587d3e10a9"
        }

        xIISLogging RootWebAppIISLogging
        {
            LogPath = "C:\SPLogs\IIS"
        }
    }
}
