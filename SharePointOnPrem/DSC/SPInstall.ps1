Configuration SPInstall
{
    param(
        $configParameters,
        $commonDictionary
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName SharePointDSC -ModuleVersion 1.9.0.0
    Import-DscResource -ModuleName xWebAdministration -ModuleVersion 1.19.0.0
    Import-DscResource -ModuleName xPendingReboot -ModuleVersion 0.3.0.0
    #preinstalling
    Import-DSCResource -ModuleName xNetworking -ModuleVersion 5.3.0.0
    Import-DSCResource -ModuleName xSQLServer -Name xSQLServerAlias -ModuleVersion 9.0.0.0
    Import-DscResource -ModuleName xCredSSP -ModuleVersion 1.3.0.0

    $SPInstallationMediaPath = $configParameters.SPInstallationMediaPath
    $SPVersion = $configParameters.SPVersion;
    $SPProductKey = $configParameters.SPProductKey;
    if ( !$SPProductKey -or ( $SPProductKey -eq "" ) )
    {
        $SPProductKey = $commonDictionary.SPVersions[ $SPVersion ].ProductKey;
    }
    Node $AllNodes.NodeName
    {
        $logFolder = $configParameters.SPLogFolder;
        
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
        
        Registry LoopBackRegistry
        {
            Ensure      = "Present"
            Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName   = "DisableLoopbackCheck"
            ValueType   = "DWORD"
            ValueData   = "1"
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
            ProductKey  = $SPProductKey
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
