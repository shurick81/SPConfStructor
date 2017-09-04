Configuration SPInstall
{
    param(
        $configParameters
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

        if ( $configParameters.SPVersion -eq "2016" )
        {

            xPendingReboot RebootAfterSPPrereqsInstalling
            { 
                Name        = 'AfterSPPrereqsInstalling'
                DependsOn   = "[SPInstallPrereqs]SPPrereqs"
            }

            $installationDependsOn = "[xPendingReboot]RebootAfterSPPrereqsInstalling"
        } else { $installationDependsOn = "[SPInstallPrereqs]SPPrereqs" }
        
        SPInstall InstallSharePoint 
        { 
            Ensure      = "Present"
            BinaryDir   = $configParameters.SPInstallationMediaPath
            ProductKey  = $configParameters.SPProductKey
            DependsOn   = $installationDependsOn
        }

        xIISLogging RootWebAppIISLogging
        {
            LogPath     = "$logFolder\IIS"
            DependsOn   = $installationDependsOn,"[File]LogFolder"
        }

        xPendingReboot RebootAfterSPInstalling
        { 
            Name        = 'AfterSPInstalling'
            DependsOn   = "[SPInstall]InstallSharePoint"
        }

    }
}
