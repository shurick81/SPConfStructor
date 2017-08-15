Configuration SPDomainDevEnv
{
    param(
        $configParameters
    )
    $DomainName = $configParameters.DomainName;
    $DomainSafeModeAdministratorPassword = $configParameters.DomainSafeModeAdministratorPassword;
    $domainAdminUserName = $configParameters.DomainAdminUserName;
    $SPInstallAccountUserName = $configParameters.SPInstallAccountUserName;
    $SPFarmAccountUserName = $configParameters.SPFarmAccountUserName;
    $SPWebAppPoolAccountUserName = $configParameters.SPWebAppPoolAccountUserName;
    $SPServicesAccountUserName = $configParameters.SPServicesAccountUserName;
    $SPSearchServiceAccountUserName = $configParameters.SPSearchServiceAccountUserName;
    $SPCrawlerAccountUserName = $configParameters.SPCrawlerAccountUserName;
    $SPTestAccountUserName = $configParameters.SPTestAccountUserName;
    $SPSecondTestAccountUserName = $configParameters.SPSecondTestAccountUserName;

    $shortDomainName = $DomainName.Substring( 0, $DomainName.IndexOf( "." ) )

    # examining, generatig and requesting credentials
        if ( !$DomainAdminCredential )
        {
            if ( $domainAdminUserName )
            {
                $securedPassword = ConvertTo-SecureString $configParameters.DomainAdminPassword -AsPlainText -Force
                $domainAdminCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$domainAdminUserName", $securedPassword )
            } else {
                $domainAdminCredential = Get-Credential -Message "Credential with domain administrator privileges";
            }
        }

        if ( !$DomainSafeModeAdministratorPasswordCredential )
        {
            if ( $DomainSafeModeAdministratorPassword )
            {
                $securedPassword = ConvertTo-SecureString $configParameters.DomainSafeModeAdministratorPassword -AsPlainText -Force
                $DomainSafeModeAdministratorPasswordCredential = New-Object System.Management.Automation.PSCredential( "anyidentity", $securedPassword )
            } else {
                $DomainSafeModeAdministratorPasswordCredential = Get-Credential -Message "Enter any but not empty login and safe mode password";
            }
        }

        if ( !$SPInstallAccountCredential )
        {
            if ( $SPInstallAccountUserName )
            {
                $securedPassword = ConvertTo-SecureString $configParameters.SPInstallAccountPassword -AsPlainText -Force
                $SPInstallAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPInstallAccountUserName", $securedPassword )
            } else {
                $SPInstallAccountCredential = Get-Credential -Message "Credential for SharePoint install account";
            }
        }

        if ( !$SPFarmAccountCredential )
        {
            if ( $SPFarmAccountUserName )
            {
                $securedPassword = ConvertTo-SecureString $configParameters.SPFarmAccountPassword -AsPlainText -Force
                $SPFarmAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPFarmAccountUserName", $securedPassword )
            } else {
                $SPFarmAccountCredential = Get-Credential -Message "Credential for SharePoint farm account";
            }
        }

        if ( !$SPWebAppPoolAccountCredential )
        {
            if ( $SPWebAppPoolAccountUserName )
            {
                $securedPassword = ConvertTo-SecureString $configParameters.SPWebAppPoolAccountPassword -AsPlainText -Force
                $SPWebAppPoolAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPWebAppPoolAccountUserName", $securedPassword )
            } else {
                $SPWebAppPoolAccountCredential = Get-Credential -Message "Credential for SharePoint Web Application app pool account";
            }
        }

        if ( !$SPServicesAccountCredential )
        {
            if ( $SPServicesAccountUserName )
            {
                $securedPassword = ConvertTo-SecureString $configParameters.SPServicesAccountPassword -AsPlainText -Force
                $SPServicesAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPServicesAccountUserName", $securedPassword )
            } else {
                $SPServicesAccountCredential = Get-Credential -Message "Credential for SharePoint shared services app pool";
            }
        }

        if ( !$SPSearchServiceAccountCredential )
        {
            if ( $SPSearchServiceAccountUserName )
            {
                $securedPassword = ConvertTo-SecureString $configParameters.SPSearchServiceAccountPassword -AsPlainText -Force
                $SPSearchServiceAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPSearchServiceAccountUserName", $securedPassword )
            } else {
                $SPSearchServiceAccountCredential = Get-Credential -Message "Credential for SharePoint search service account";
            }
        }

        if ( !$SPCrawlerAccountCredential )
        {
            if ( $SPCrawlerAccountUserName )
            {
                $securedPassword = ConvertTo-SecureString $configParameters.SPCrawlerAccountPassword -AsPlainText -Force
                $SPCrawlerAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPCrawlerAccountUserName", $securedPassword )
            } else {
                $SPCrawlerAccountCredential = Get-Credential -Message "Credential for SharePoint crawler account";
            }
        }

        if ( !$SPTestAccountCredential )
        {
            if ( $SPTestAccountUserName )
            {
                $securedPassword = ConvertTo-SecureString $configParameters.SPTestAccountPassword -AsPlainText -Force
                $SPTestAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPTestAccountUserName", $securedPassword )
            } else {
                $SPTestAccountCredential = Get-Credential -Message "Credential for SharePoint test user";
            }
        }

        if ( !$SPSecondTestAccountCredential )
        {
            if ( $SPSecondTestAccountUserName )
            {
                $securedPassword = ConvertTo-SecureString $configParameters.SPSecondTestAccountPassword -AsPlainText -Force
                $SPSecondTestAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPSecondTestAccountUserName", $securedPassword )
            } else {
                $SPSecondTestAccountCredential = Get-Credential -Message "Credential for SharePoint test user";
            }
        }

        $SPOCAccountPass = ConvertTo-SecureString "Any3ligiblePa`$`$" -AsPlainText -Force
        $SPOCAccountCredential = New-Object System.Management.Automation.PSCredential( "anyusername", $SPOCAccountPass )

    # credentials are ready

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xRemoteDesktopAdmin
    Import-DscResource -ModuleName xActiveDirectory

    Node $DCMachineName
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
        xRemoteDesktopAdmin DCRDPSettings
        {
           Ensure               = 'Present'
           UserAuthentication   = 'NonSecure'
        }

        WindowsFeatureSet DomainFeatures
        {
            Name                    = @("DNS", "AD-Domain-Services", "RSAT-ADDS")
            Ensure                  = 'Present'
            IncludeAllSubFeature    = $true
        } 
                
        xADDomain ADDomain
        {
            DomainName                      = $DomainName
            DomainAdministratorCredential   = $DomainAdminCredential
            SafemodeAdministratorPassword   = $DomainSafeModeAdministratorPasswordCredential
            DependsOn                       = @("[WindowsFeatureSet]DomainFeatures", "[xRemoteDesktopAdmin]DCRDPSettings")
        }

        xWaitForADDomain WaitForDomain
        {
            DomainName              = $DomainName
            DomainUserCredential    = $DomainAdminCredential
            RetryCount              = 100
            RetryIntervalSec        = 10
            DependsOn               = "[xADDomain]ADDomain"
        }

        xADUser SPInstallAccountUser
        {
            DomainName  = $DomainName
            UserName    = $SPInstallAccountCredential.GetNetworkCredential().UserName
            Password    = $SPInstallAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPFarmAccountUser
        {
            DomainName  = $DomainName
            UserName    = $SPFarmAccountCredential.GetNetworkCredential().UserName
            Password    = $SPFarmAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPWebAppPoolAccountUser
        {
            DomainName  = $DomainName
            UserName    = $SPWebAppPoolAccountCredential.GetNetworkCredential().UserName
            Password    = $SPWebAppPoolAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPServicesAccountUser
        {
            DomainName  = $DomainName
            UserName    = $SPServicesAccountCredential.GetNetworkCredential().UserName
            Password    = $SPServicesAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPSearchServiceAccountUser
        {
            DomainName  = $DomainName
            UserName    = $SPSearchServiceAccountCredential.GetNetworkCredential().UserName
            Password    = $SPSearchServiceAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPCrawlerAccountUser
        {
            DomainName  = $DomainName
            UserName    = $SPCrawlerAccountCredential.GetNetworkCredential().UserName
            Password    = $SPCrawlerAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPOCSuperUserADUser
        {
            DomainName  = $DomainName
            UserName    = $configParameters.SPOCSuperUser
            Password    = $SPOCAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPOCSuperReaderUser
        {
            DomainName  = $DomainName
            UserName    = $configParameters.SPOCSuperReader
            Password    = $SPOCAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPTestUser
        {
            DomainName  = $DomainName
            UserName    = $SPTestAccountCredential.GetNetworkCredential().UserName
            Password    = $SPTestAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPSecondTestUser
        {
            DomainName  = $DomainName
            UserName    = $SPSecondTestAccountCredential.GetNetworkCredential().UserName
            Password    = $SPSecondTestAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADGroup SPAdminGroup
        {
            GroupName           = $configParameters.SPAdminGroupName
            Ensure              = "Present"
            MembersToInclude    = $SPInstallAccountCredential.GetNetworkCredential().UserName
            DependsOn           = "[xADUser]SPInstallAccountUser"
        }

        xADGroup SPMemberGroup
        {
            GroupName           = $configParameters.SPMemberGroupName
            Ensure              = "Present"
            MembersToInclude    = $SPTestAccountCredential.GetNetworkCredential().UserName
            DependsOn           = "[xADUser]SPInstallAccountUser"
        }

        xADGroup SPVisitorGroup
        {
            GroupName           = $configParameters.SPVisitorGroupName
            Ensure              = "Present"
            MembersToInclude    = $SPSecondTestAccountCredential.GetNetworkCredential().UserName
            DependsOn           = "[xADUser]SPInstallAccountUser"
        }
    }
}

$configParameters = Import-PowershellDataFile configparemeters.psd1;
$DCMachineName = $configParameters.DCMachineName;
$configurationData = @{ AllNodes = @(
    @{ NodeName = $configParameters.DCMachineName; PSDscAllowPlainTextPassword = $True }
) }
SPDomainDevEnv -ConfigurationData $configurationData -ConfigParameters $configParameters

