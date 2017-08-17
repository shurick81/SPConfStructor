Configuration SP2013Ent
{
    param(
        $configParameters
    )
    $DomainName = $configParameters.DomainName;
    $domainAdminUserName = $configParameters.DomainAdminUserName;
    $SPInstallAccountUserName = $configParameters.SPInstallAccountUserName;
    $SPFarmAccountUserName = $configParameters.SPFarmAccountUserName;
    $SPWebAppPoolAccountUserName = $configParameters.SPWebAppPoolAccountUserName;
    $SPServicesAccountUserName = $configParameters.SPServicesAccountUserName;
    $SPSearchServiceAccountUserName = $configParameters.SPSearchServiceAccountUserName;
    $SPCrawlerAccountUserName = $configParameters.SPCrawlerAccountUserName;
    $SPPassPhrase = $configParameters.SPPassPhrase;
    $SQLPass = $configParameters.SQLPass;
    $searchIndexDirectory = $configParameters.searchIndexDirectory;
    $SPSiteCollectionHostName = $configParameters.SPSiteCollectionHostName;

    $shortDomainName = $DomainName.Substring( 0, $DomainName.IndexOf( "." ) );
    $webAppHostName = "SP2013_01.$DomainName";

    # examining, generating and requesting credentials
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

        if ( !$SPPassphraseCredential )
        {
            if ( $SPPassPhrase )
            {
                $securedPassword = ConvertTo-SecureString $SPPassPhrase -AsPlainText -Force
                $SPPassphraseCredential = New-Object System.Management.Automation.PSCredential( "anyidentity", $securedPassword )
            } else {
                $SPPassphraseCredential = Get-Credential -Message "Enter any user name and enter pass phrase in password field";
            }
        }

        if ( !$SQLPassCredential )
        {
            if ( $SQLPass )
            {
                $securedPassword = ConvertTo-SecureString $SQLPass -AsPlainText -Force
                $SQLPassCredential = New-Object System.Management.Automation.PSCredential( "anyidentity", $securedPassword )
            } else {
                $SQLPassCredential = Get-Credential -Message "Enter any user name and enter SQL SA password";
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

    # credentials are ready

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -Module xSystemSecurity -Name xIEEsc
    Import-DSCResource -ModuleName xDSCDomainJoin
    Import-DSCResource -ModuleName xNetworking
    Import-DSCResource -ModuleName xSQLServer -Name xSQLServerAlias
    Import-DscResource -ModuleName xCredSSP
    Import-DSCResource -ModuleName SharePointDSC
    Import-DscResource -ModuleName xWebAdministration

    Node $SP2016EntDevMachineName
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
        
        xDNSServerAddress DNSClient
        {
            Address         = $configParameters.DomainControllerIP
            AddressFamily   = "IPv4"
            InterfaceAlias  = "Ethernet 3"
        }
                
        xDSCDomainJoin DomainJoin
        {
            Domain      = $DomainName
            Credential  = $DomainAdminCredential
            DependsOn   = @("[xDNSServerAddress]DNSClient","[Registry]LoopBackRegistry")
        }
        
        #Local group
        Group AdminGroup
        {
            GroupName           = "Administrators"
            Credential          = $DomainAdminCredential
            MembersToInclude    = "$shortDomainName\$($configParameters.SPAdminGroupName)"
            DependsOn           = "[xDSCDomainJoin]DomainJoin"
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
                
        SPInstallPrereqs SP2016Prereqs
        {
            InstallerPath   = "C:\Install\SharePoint 2016\Prerequisiteinstaller.exe"
            OnlineMode      = $true
        }
        
        SPInstall InstallSharePoint 
        { 
            Ensure      = "Present"
            BinaryDir   = "C:\Install\SharePoint 2016"
            ProductKey  = $configParameters.SPProductKey
            DependsOn   = "[SPInstallPrereqs]SP2016Prereqs"
        }

        xSQLServerAlias SPDBAlias
        {
            Ensure               = 'Present'
            Name                 = $configParameters.SPDatabaseAlias
            ServerName           = $configParameters.SPDatabaseServer
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
            Passphrase                = $SPPassphraseCredential
            FarmAccount               = $SPFarmAccountCredential
            RunCentralAdmin           = $true
            CentralAdministrationPort = 7777
            ServerRole                = "SingleServerFarm"
            InstallAccount            = $SPInstallAccountCredential
            DependsOn                 = @( "[xFireWall]SQLFirewallRule", "[SPInstall]InstallSharePoint", "[xSQLServerSetup]SQLSetup", "[Group]AdminGroup", "[xCredSSP]CredSSPServer", "[xCredSSP]CredSSPClient", "[xSQLServerAlias]SPDBAlias" )
        }

        SPDiagnosticLoggingSettings ApplyDiagnosticLogSettings
        {
            LogPath         = "C:\SPLogs\ULS"
            LogSpaceInGB    = 10
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPFarm]Farm"
        }
        
        SPManagedAccount ApplicationWebPoolAccount
        {
            AccountName     = $SPWebAppPoolAccountCredential.UserName
            Account         = $SPWebAppPoolAccountCredential
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPFarm]Farm"
        }

        SPWebApplication RootWebApp
        {
            Name                    = "RootWebApp"
            ApplicationPool         = "All Web Application"
            ApplicationPoolAccount  = $SPWebAppPoolAccountCredential.UserName
            Url                     = "http://$webAppHostName"
            DatabaseName            = "SP_Content_01"
            AuthenticationMethod    = "NTLM"
            InstallAccount          = $SPInstallAccountCredential
            DependsOn               = "[SPManagedAccount]ApplicationWebPoolAccount"
        }

        xIISLogging RootWebAppIISLogging
        {
            LogPath = "C:\SPLogs\IIS"
        }

        SPCacheAccounts CacheAccounts
        {
            WebAppUrl            = "http://$webAppHostName"
            SuperUserAlias       = "$shortDomainName\$($configParameters.SPOCSuperUser)"
            SuperReaderAlias     = "$shortDomainName\$($configParameters.SPOCSuperReader)"
            InstallAccount       = $SPInstallAccountCredential
            DependsOn            = "[SPWebApplication]RootWebApp"
        }

        SPWebAppPolicy RootWebAppPolicy
        {
            WebAppUrl               = "RootWebApp"
            MembersToInclude        = @(
                MSFT_SPWebPolicyPermissions {
                    Username        = $SPInstallAccountCredential.UserName
                    PermissionLevel = "Full Control"
                    IdentityType    = "Claims"
                }
            )
            SetCacheAccountsPolicy = $true
            InstallAccount         = $SPInstallAccountCredential
            DependsOn              = "[SPCacheAccounts]CacheAccounts"
        }

        SPSite RootPathSite
        {
            Url             = "http://$webAppHostName"
            OwnerAlias      = $SPInstallAccountCredential.UserName
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPWebApplication]RootWebApp"
        }

        SPSite RootHostSite
        {
            Url                         = "http://$SPSiteCollectionHostName"
            OwnerAlias                  = $SPInstallAccountCredential.UserName
            Template                    = "STS#0"
            HostHeaderWebApplication    = "http://$webAppHostName"
            InstallAccount              = $SPInstallAccountCredential
            DependsOn                   = "[SPSite]RootPathSite"
        }
        
        #this needs to be troubleshooted
        Registry LocalZone
        {
            Ensure                  = "Present"
            Key                     = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\$DomainName\sp2016entdev"
            ValueName               = "HTTP"
            ValueType               = "DWORD"
            ValueData               = "1"
            PsDscRunAsCredential    = $SPInstallAccountCredential
        }

        SPManagedAccount SharePointServicesPoolAccount
        {
            AccountName     = $SPServicesAccountCredential.UserName
            Account         = $SPServicesAccountCredential
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPFarm]Farm"
        }

        SPServiceAppPool SharePointServicesAppPool
        {
            Name            = "SharePoint Services App Pool"
            ServiceAccount  = $SPServicesAccountCredential.UserName
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPManagedAccount]SearchServicePoolAccount"
        }

        SPAccessServiceApp AccessServices
        {
            Name            = "Access Services"
            ApplicationPool = "SharePoint Services App Pool";
            DatabaseServer  = $NodeName
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPBCSServiceApp BCSServiceApp
        {
            Name            = "Business Data Connectivity Service"
            ApplicationPool = "SharePoint Services App Pool";
            DatabaseServer  = $NodeName
            DatabaseName    = "SP_BCS"
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPManagedMetaDataServiceApp ManagedMetadataServiceApp
        {
            DatabaseName    = "SP_Metadata";
            ApplicationPool = "SharePoint Services App Pool";
            ProxyName       = "Managed Metadata Service Application";
            Name            = "Managed Metadata Service Application";
            Ensure          = "Present";
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPPerformancePointServiceApp PerformancePoint
        {
            Name            = "PerformancePoint Service Application"
            ApplicationPool = "SharePoint Services App Pool";
            DatabaseName    = "SP_PerformancePoint"
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPSecureStoreServiceApp SecureStoreServiceApp
        {
            Name            = "Secure Store Service"
            ApplicationPool = "SharePoint Services App Pool"
            AuditingEnabled = $true
            DatabaseName    = "SP_SecureStoreService"
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPStateServiceApp StateServiceApp
        {
            Name            = "State Service"
            DatabaseName    = "SP_StateService"
            Ensure          = "Present"
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPSubscriptionSettingsServiceApp SubscriptionSettingsServiceApp
        {
            Name            = "Subscription Settings Service Application"
            ApplicationPool = "SharePoint Services App Pool"
            DatabaseName    = "SP_SubscriptionSettings"
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPAppManagementServiceApp AppManagementServiceApp
        {
            Name            = "App Management Service Application"
            ApplicationPool = "SharePoint Services App Pool"
            DatabaseName    = "SP_AppManagement"
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPSubscriptionSettingsServiceApp]SubscriptionSettingsServiceApp"
        }

        SPUsageApplication UsageApplication 
        {
            Name                    = "Usage Service Application"
            DatabaseName            = "SP_Usage"
            UsageLogCutTime         = 5
            UsageLogLocation        = "C:\SPLogs\Usage"
            UsageLogMaxFileSizeKB   = 1024
            InstallAccount          = $SPInstallAccountCredential
            DependsOn               = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPManagedAccount SearchServicePoolAccount
        {
            AccountName     = $SPSearchServiceAccountCredential.UserName
            Account         = $SPSearchServiceAccountCredential
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPFarm]Farm"
        }

        SPServiceAppPool SearchServiceAppPool
        {
            Name            = "SharePoint Search App Pool"
            ServiceAccount  = $SPSearchServiceAccountCredential.UserName
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPManagedAccount]SearchServicePoolAccount"
        }

        SPSite SearchCenterSite
        {
            Url                         = "http://$SPSiteCollectionHostName/sites/searchcenter"
            OwnerAlias                  = $SPInstallAccountCredential.UserName
            Template                    = "SRCHCEN#0"
            HostHeaderWebApplication    = "http://$webAppHostName"
            InstallAccount              = $SPInstallAccountCredential
            DependsOn                   = "[SPSite]RootPathSite"
        }

        SPSearchServiceApp EnterpriseSearchServiceApplication
        {
            Name                        = "Search Service Application";
            Ensure                      = "Present";
            ApplicationPool             = "SharePoint Search App Pool";
            SearchCenterUrl             = "http://$SPSiteCollectionHostName/sites/searchcenter/pages";
            DatabaseName                = "SP_Search";
            DefaultContentAccessAccount = $SPCrawlerAccountCredential;
            InstallAccount              = $SPInstallAccountCredential
            DependsOn                   = @("[SPUsageApplication]UsageApplication","[SPServiceAppPool]SearchServiceAppPool","[SPSite]SearchCenterSite")
        }

        File "IndexFolder"
        {
            DestinationPath = $searchIndexDirectory
            Type            = "Directory"
        }

        SPSearchTopology SearchTopology
        {
            ServiceAppName          = "Search Service Application";
            ContentProcessing       = @($NodeName);
            AnalyticsProcessing     = @($NodeName);
            IndexPartition          = @($NodeName);
            Crawler                 = @($NodeName);
            Admin                   = @($NodeName);
            QueryProcessing         = @($NodeName);
            FirstPartitionDirectory = $searchIndexDirectory;
            InstallAccount          = $SPInstallAccountCredential
            DependsOn = @("[SPSearchServiceApp]EnterpriseSearchServiceApplication","[File]IndexFolder");
        }

        SPSearchContentSource WebsiteSource
        {
            ServiceAppName       = "Search Service Application"
            Name                 = "Local SharePoint sites"
            ContentSourceType    = "SharePoint"
            Addresses            = @("http://$webAppHostName")
            CrawlSetting         = "CrawlEverything"
            ContinuousCrawl      = $true
            FullSchedule         = MSFT_SPSearchCrawlSchedule{
                                    ScheduleType = "Weekly"
                                    CrawlScheduleDaysOfWeek = @("Monday", "Wednesday", "Friday")
                                    StartHour = "3"
                                    StartMinute = "0"
                                   }
            Priority             = "Normal"
            Ensure               = "Present"
            InstallAccount       = $SPInstallAccountCredential
            DependsOn            = "[SPSearchTopology]SearchTopology"
        }
        
        SPSite MySite
        {
            Url                         = "http://$SPSiteCollectionHostName/sites/my"
            OwnerAlias                  = $SPInstallAccountCredential.UserName
            Template                    = "SPSMSITEHOST#0"
            HostHeaderWebApplication    = "http://$webAppHostName"
            InstallAccount              = $SPInstallAccountCredential
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
            FarmAccount         = $SPFarmAccountCredential
            InstallAccount      = $SPInstallAccountCredential
            DependsOn           = @("[SPServiceAppPool]SharePointServicesAppPool","[SPSite]MySite")
        }

        SPVisioServiceApp VisioServices
        {
            Name            = "Visio Graphics Service"
            ApplicationPool = "SharePoint Services App Pool"
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        }

        SPWordAutomationServiceApp WordAutomation 
        { 
            Name            = "Word Automation Service" 
            Ensure          = "Present"
            ApplicationPool = "SharePoint Services App Pool"
            DatabaseName    = "SP_WordAutomation"
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPServiceAppPool]SharePointServicesAppPool"
        } 
    }
}
<#
$configParameters = Import-PowershellDataFile configparemeters.psd1;
$SP2016EntDevMachineName = $configParameters.SP2016EntDevMachineName
$configurationData = @{ AllNodes = @(
    @{ NodeName = $SP2016EntDevMachineName; PSDscAllowPlainTextPassword = $True }
) }
SP2013EntDevEnv -ConfigurationData $configurationData -ConfigParameters $configParameters
#>
