Configuration SPInstall
{
    param(
        $configParameters,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName SharePointDSC
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName xPendingReboot
    #preinstalling
    Import-DSCResource -ModuleName xSQLServer -Name xSQLServerAlias
    Import-DSCResource -ModuleName SharePointDSC


    Node $AllNodes.NodeName
    {
        $logFolder = $configParameters.SPLogFolder;
        #Only needed for manual mof installation, not for automated?
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
        
        File LogFolder
        {
            Type            = "Directory"
            DestinationPath = $logFolder
        }
        
        SPInstallPrereqs SPPrereqs
        {
            InstallerPath   = "$($configParameters.SPInstallationMediaPath)\Prerequisiteinstaller.exe"
            OnlineMode      = $true
        }

        SPInstall InstallSharePoint 
        { 
            Ensure      = "Present"
            BinaryDir   = $configParameters.SPInstallationMediaPath
            ProductKey  = $configParameters.SPProductKey
            DependsOn   = "[SPInstallPrereqs]SPPrereqs"
        }

        xIISLogging RootWebAppIISLogging
        {
            LogPath     = "$logFolder\IIS"
            DependsOn   = "[SPInstallPrereqs]SPPrereqs","[File]LogFolder"
        }

        xPendingReboot RebootAfterSPInstalling
        { 
            Name        = 'AfterSPInstalling'
            DependsOn   = "[SPInstall]InstallSharePoint"
        }

    }
}
