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

    $SPInstallationMediaPath = $configParameters.SPInstallationMediaPath
    $SPVersion = $configParameters.SPVersion;

    Node $AllNodes.NodeName
    {
        $logFolder = $configParameters.SPLogFolder;
        
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
            InstallerPath   = "$SPInstallationMediaPath\$SPVersion\SharePoint\Prerequisiteinstaller.exe"
            OnlineMode      = $true
        }

        if ( $SPVersion -eq "2016" )
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
            BinaryDir   = "$SPInstallationMediaPath\$SPVersion\SharePoint"
            ProductKey  = $configParameters.SPProductKey
            DependsOn   = $installationDependsOn
        }

        $languages = $configParameters.SPLanguagePacks.Split(",")
        $resourceCounter = 0;
        $languages | % {

            SPInstallLanguagePack "InstallLPBinaries$resourceCounter"
            {
                BinaryDir  = "$SPInstallationMediaPath\$SPVersion\LanguagePacks\$_"
                Ensure     = "Present"
                DependsOn   = "[SPInstall]InstallSharePoint"
            }

            $resourceCounter++;
        }
        
        xIISLogging RootWebAppIISLogging
        {
            LogPath     = "$logFolder\IIS"
            DependsOn   = $installationDependsOn,"[File]LogFolder"
        }

        <#
        xPendingReboot RebootAfterSPInstalling
        { 
            Name        = 'AfterSPInstalling'
            DependsOn   = "[SPInstall]InstallSharePoint"
        }
        #>

    }
}
