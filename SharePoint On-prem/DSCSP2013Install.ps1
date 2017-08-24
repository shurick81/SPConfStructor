Configuration SP2013Install
{
    param(
        $configParameters,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $LocalAdminCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPendingReboot
    Import-DSCResource -Module xSystemSecurity -Name xIEEsc
    Import-DsCResource -Module xWindowsUpdate -Name xHotfix
    Import-DSCResource -ModuleName SharePointDSC
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        #Only needed for manual mof installation, not for automated?
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
         
        File LogFolder
        {
            Type            = "Directory"
            DestinationPath = "C:\SPLogs"
        }

        Registry LoopBackRegistry
        {
            Ensure      = "Present"  # You can also set Ensure to "Absent"
            Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName   = "DisableLoopbackCheck"
            ValueType   = "DWORD"
            ValueData   = "1"
        }

        #needed for SP2013RTM Only?
        xHotfix RemoveDotNet47
        {
            Ensure  = "Absent"
            Path    = "C:/anyfolder/KB3186505.msu"
            Id      = "KB3186505"
        }

        xPendingReboot RebootAfterNETUninstalling
        { 
            Name        = 'AfterNETUninstalling'
            DependsOn   = "[xHotfix]RemoveDotNet47"
        }

        xIEEsc DisableIEEsc
        {
            IsEnabled   = $false
            UserRole    = "Administrators"
        }
        
        SPInstallPrereqs SP2016Prereqs
        {
            InstallerPath           = "C:\Install\SPExtracted\Prerequisiteinstaller.exe"
            OnlineMode              = $true
            PsDscRunAsCredential    = $LocalAdminCredential
            DependsOn               = "[xPendingReboot]RebootAfterNETUninstalling"
        }

        xPendingReboot RebootBeforeSPInstalling
        { 
            Name        = 'BeforeSPInstalling'
            DependsOn   = "[SPInstallPrereqs]SP2016Prereqs"
        }
        
        SPInstall InstallSharePoint 
        { 
            Ensure      = "Present"
            BinaryDir   = "C:\Install\SPExtracted"
            ProductKey  = $configParameters.SPProductKey
            DependsOn   = "[SPInstallPrereqs]SP2016Prereqs"
        }

        xIISLogging RootWebAppIISLogging
        {
            LogPath     = "C:\SPLogs\IIS"
            DependsOn   = "[SPInstallPrereqs]SP2016Prereqs","[File]LogFolder"
        }

    }
}
