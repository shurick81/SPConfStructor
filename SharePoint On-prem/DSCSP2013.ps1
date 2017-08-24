Configuration SP2013
{
    param(
        $configParameters
    )
    $DomainName = $configParameters.DomainName;
    $searchIndexDirectory = $configParameters.searchIndexDirectory;
    $SPSiteCollectionHostName = $configParameters.SPSiteCollectionHostName;

    $shortDomainName = $DomainName.Substring( 0, $DomainName.IndexOf( "." ) );
    $webAppHostName = "SP2013_01.$DomainName";

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xNetworking
    Import-DSCResource -ModuleName xSQLServer -Name xSQLServerAlias
    Import-DscResource -ModuleName xCredSSP
    Import-DSCResource -ModuleName SharePointDSC
    Import-DscResource -ModuleName xWebAdministration

    $SPMachines = $configParameters.Machines | ? { $_.Roles -contains "SharePoint" } | % { $_.Name }

    Node $AllNodes.NodeName
    {
        
        xHostsFile WAHostEntry
        {
            HostName  =  $webAppHostName
            IPAddress = "127.0.0.1"
            Ensure    = "Present"
        }
        
        xHostsFile SiteHostEntry
        {
            HostName  = $SPSiteCollectionHostName
            IPAddress = "127.0.0.1"
            Ensure    = "Present"
        }
                
        xSQLServerAlias SPDBAlias
        {
            Ensure      = 'Present'
            Name        = $configParameters.SPDatabaseAlias
            ServerName  = $configParameters.SPDatabaseServer
        }

        xCredSSP CredSSPServer
        {
            Ensure  = "Present"
            Role    = "Server"
        }

        xCredSSP CredSSPClient
        {
            Ensure = "Present";
            Role = "Client";
            DelegateComputers = "*.$DomainName"
        }

        SPFarm Farm
        {
            Ensure                    = "Present"
            DatabaseServer            = $configParameters.SPDatabaseAlias
            FarmConfigDatabaseName    = "SP_Config"
            AdminContentDatabaseName  = "SP_AdminContent"
            Passphrase                = $configParameters.SPPassphraseCredential
            FarmAccount               = $configParameters.SPFarmAccountCredential
            RunCentralAdmin           = $true
            CentralAdministrationPort = 50555
            InstallAccount            = $configParameters.SPInstallAccountCredential
            DependsOn                 = @( "[xCredSSP]CredSSPServer", "[xCredSSP]CredSSPClient", "[xSQLServerAlias]SPDBAlias" )
        }

        #this needs to be troubleshooted
        Registry LocalZone
        {
            Ensure                  = "Present"
            Key                     = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\$DomainName\sp2016entdev"
            ValueName               = "HTTP"
            ValueType               = "DWORD"
            ValueData               = "1"
            PsDscRunAsCredential    = $configParameters.SPInstallAccountCredential
        }
    }

    $WFEMachines = $configParameters.Machines | ? { $_.Roles -contains "WFE" } | % { $_.Name }
    
    Node $WFEMachines
    {

        #WFE service instances. Options: https://www.powershellgallery.com/packages/SharePointDSC/1.6.0.0/Content/DSCResources%5CMSFT_SPServiceInstance%5CMSFT_SPServiceInstance.psm1
        SPServiceInstance ManagedMetadataServiceInstance
        {
            Name            = "Access Database Service 2010"
            InstallAccount  = $configParameters.SPInstallAccountCredential
        }

    }

    $ApplicationMachines = $configParameters.Machines | ? { $_.Roles -contains "Application" } | % { $_.Name }

    Node $ApplicationMachines
    {
        SPDiagnosticLoggingSettings ApplyDiagnosticLogSettings
        {
            LogPath         = "C:\SPLogs\ULS"
            LogSpaceInGB    = 10
            InstallAccount  = $configParameters.SPInstallAccountCredential
        }

        SPManagedAccount ApplicationWebPoolAccount
        {
            AccountName     = $configParameters.SPWebAppPoolAccountCredential.UserName
            Account         = $configParameters.SPWebAppPoolAccountCredential
            InstallAccount  = $configParameters.SPInstallAccountCredential
        }

        SPWebApplication RootWebApp
        {
            Name                    = "RootWebApp"
            ApplicationPool         = "All Web Application"
            ApplicationPoolAccount  = $configParameters.SPWebAppPoolAccountCredential.UserName
            Url                     = "http://$webAppHostName"
            DatabaseName            = "SP_Content_01"
            AuthenticationMethod    = "NTLM"
            InstallAccount          = $configParameters.SPInstallAccountCredential
            DependsOn               = "[SPManagedAccount]ApplicationWebPoolAccount"
        }

        SPCacheAccounts CacheAccounts
        {
            WebAppUrl            = "http://$webAppHostName"
            SuperUserAlias       = "$shortDomainName\$($configParameters.SPOCSuperUser)"
            SuperReaderAlias     = "$shortDomainName\$($configParameters.SPOCSuperReader)"
            InstallAccount       = $configParameters.SPInstallAccountCredential
            DependsOn            = "[SPWebApplication]RootWebApp"
        }

        SPWebAppPolicy RootWebAppPolicy
        {
            WebAppUrl               = "RootWebApp"
            MembersToInclude        = @(
                MSFT_SPWebPolicyPermissions {
                    Username        = $configParameters.SPInstallAccountCredential.UserName
                    PermissionLevel = "Full Control"
                    IdentityType    = "Claims"
                }
            )
            SetCacheAccountsPolicy = $true
            InstallAccount         = $configParameters.SPInstallAccountCredential
            DependsOn              = "[SPCacheAccounts]CacheAccounts"
        }

        SPSite RootPathSite
        {
            Url             = "http://$webAppHostName"
            OwnerAlias      = $configParameters.SPInstallAccountCredential.UserName
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPWebApplication]RootWebApp"
        }

        SPSite RootHostSite
        {
            Url                         = "http://$SPSiteCollectionHostName"
            OwnerAlias                  = $configParameters.SPInstallAccountCredential.UserName
            Template                    = "STS#0"
            HostHeaderWebApplication    = "http://$webAppHostName"
            InstallAccount              = $configParameters.SPInstallAccountCredential
            DependsOn                   = "[SPSite]RootPathSite"
        }
        
        SPManagedAccount SharePointServicesPoolAccount
        {
            AccountName     = $configParameters.SPServicesAccountCredential.UserName
            Account         = $configParameters.SPServicesAccountCredential
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPFarm]Farm"
        }

        SPServiceAppPool SharePointServicesAppPool
        {
            Name            = "SharePoint Services App Pool"
            ServiceAccount  = $configParameters.SPServicesAccountCredential.UserName
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPManagedAccount]SharePointServicesPoolAccount"
        }

        SPAccessServiceApp AccessServices
        {
            Name            = "Access Services"
            ApplicationPool = "SharePoint Services App Pool";
            DatabaseServer  = $configParameters.SPDatabaseAlias
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPBCSServiceApp BCSServiceApp
        {
            Name            = "Business Data Connectivity Service"
            ApplicationPool = "SharePoint Services App Pool";
            DatabaseServer  = $configParameters.SPDatabaseAlias
            DatabaseName    = "SP_BCS"
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPManagedMetaDataServiceApp ManagedMetadataServiceApp
        {
            DatabaseName    = "SP_Metadata";
            ApplicationPool = "SharePoint Services App Pool";
            ProxyName       = "Managed Metadata Service Application";
            Name            = "Managed Metadata Service Application";
            Ensure          = "Present";
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPPerformancePointServiceApp PerformancePoint
        {
            Name            = "PerformancePoint Service Application"
            ApplicationPool = "SharePoint Services App Pool";
            DatabaseName    = "SP_PerformancePoint"
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPSecureStoreServiceApp SecureStoreServiceApp
        {
            Name            = "Secure Store Service"
            ApplicationPool = "SharePoint Services App Pool"
            AuditingEnabled = $true
            DatabaseName    = "SP_SecureStoreService"
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPStateServiceApp StateServiceApp
        {
            Name            = "State Service"
            DatabaseName    = "SP_StateService"
            Ensure          = "Present"
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPSubscriptionSettingsServiceApp SubscriptionSettingsServiceApp
        {
            Name            = "Subscription Settings Service Application"
            ApplicationPool = "SharePoint Services App Pool"
            DatabaseName    = "SP_SubscriptionSettings"
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPAppManagementServiceApp AppManagementServiceApp
        {
            Name            = "App Management Service Application"
            ApplicationPool = "SharePoint Services App Pool"
            DatabaseName    = "SP_AppManagement"
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPSubscriptionSettingsServiceApp]SubscriptionSettingsServiceApp"
        }

        SPUsageApplication UsageApplication 
        {
            Name                    = "Usage Service Application"
            DatabaseName            = "SP_Usage"
            UsageLogCutTime         = 5
            UsageLogLocation        = "C:\SPLogs\Usage"
            UsageLogMaxFileSizeKB   = 1024
            InstallAccount          = $configParameters.SPInstallAccountCredential
            DependsOn               = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPSite SearchCenterSite
        {
            Url                         = "http://$SPSiteCollectionHostName/sites/searchcenter"
            OwnerAlias                  = $configParameters.SPInstallAccountCredential.UserName
            Template                    = "SRCHCEN#0"
            HostHeaderWebApplication    = "http://$webAppHostName"
            InstallAccount              = $configParameters.SPInstallAccountCredential
            DependsOn                   = "[SPSite]RootPathSite"
        }
        SPSite MySite
        {
            Url                         = "http://$SPSiteCollectionHostName/sites/my"
            OwnerAlias                  = $configParameters.SPInstallAccountCredential.UserName
            Template                    = "SPSMSITEHOST#0"
            HostHeaderWebApplication    = "http://$webAppHostName"
            InstallAccount              = $configParameters.SPInstallAccountCredential
            DependsOn                   = "[SPSite]RootPathSite"
        }

        SPUserProfileServiceApp UserProfileServiceApp
        {
            Name                = "User Profile Service Application"
            ApplicationPool     = "SharePoint Services App Pool"
            MySiteHostLocation  = "http://$SPSiteCollectionHostName/sites/my"
            ProfileDBName       = "SP_UserProfiles"
            SocialDBName        = "SP_Social"
            SyncDBName          = "SP_ProfileSync"
            EnableNetBIOS       = $false
            FarmAccount         = $configParameters.SPFarmAccountCredential
            InstallAccount      = $configParameters.SPInstallAccountCredential
            DependsOn           = @("[SPServiceAppPool]SharePointServicesAppPool","[SPSite]MySite")
        }

        SPVisioServiceApp VisioServices
        {
            Name            = "Visio Graphics Service"
            ApplicationPool = "SharePoint Services App Pool"
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPWordAutomationServiceApp WordAutomation 
        { 
            Name            = "Word Automation Service" 
            Ensure          = "Present"
            ApplicationPool = "SharePoint Services App Pool"
            DatabaseName    = "SP_WordAutomation"
            InstallAccount  = $configParameters.SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        } 
    }

    $DistributedCacheMachines = $configParameters.Machines | ? { $_.Roles -contains "DistributedCache" } | % { $_.Name }
    
    Node $DistributedCacheMachines
    {
        #DC configuration
    }

    #Configuration machines

    #Search

    $SearchQueryMachines = $configParameters.Machines | ? { $_.Roles -contains "SearchQuery" } | % { $_.Name }
    
    Node $SearchQueryMachines
    {
        File "IndexFolder"
        {
            DestinationPath = $searchIndexDirectory
            Type            = "Directory"
        }
    }

    $SearchCrawlerMachines = $configParameters.Machines | ? { $_.Roles -contains "SearchCrawl" } | % { $_.Name }

    Node $SearchCrawlerMachines
    {
        #search instances?
    }
}
