Configuration SPFarm
{
    param(
        $configParameters,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPPassphraseCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPFarmAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPInstallAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPWebAppPoolAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPServicesAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPSearchServiceAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPCrawlerAccountCredential,
        [Boolean]$GranularApplying = $false,
        [Boolean]$SearchTopologyGranule = $false
    )
    $DomainName = $configParameters.DomainName;
    $searchIndexDirectory = $configParameters.searchIndexDirectory;
    $SPSiteCollectionHostName = $configParameters.SPSiteCollectionHostName;
    $logFolder = $configParameters.SPLogFolder;

    $shortDomainName = $DomainName.Substring( 0, $DomainName.IndexOf( "." ) );
    $webAppHostName = "SPWA_01.$DomainName";

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xNetworking
    Import-DSCResource -ModuleName xSQLServer -Name xSQLServerAlias
    Import-DSCResource -ModuleName SharePointDSC

    $SPMachines = $configParameters.Machines | ? { ( $_.Roles -contains "SharePoint" ) -or ( $_.Roles -contains "SingleServerFarm" ) } | % { $_.Name }
    $WFEMachines = $configParameters.Machines | ? { ( $_.Roles -contains "WFE" ) -or ( $_.Roles -contains "SingleServerFarm" ) } | % { $_.Name }
    $ApplicationMachines = $configParameters.Machines | ? { ( $_.Roles -contains "Application" ) -or ( $_.Roles -contains "SingleServerFarm" ) } | % { $_.Name }
    $DistributedCacheMachines = $configParameters.Machines | ? { ( $_.Roles -contains "DistributedCache" ) -or ( $_.Roles -contains "SingleServerFarm" ) } | % { $_.Name }
    $SearchMachines = $configParameters.Machines | ? { ( $_.Roles -contains "SearchQuery" ) -or ( $_.Roles -contains "SearchCrawl" ) -or ( $_.Roles -contains "SingleServerFarm" ) } | % { $_.Name }
    $SearchQueryMachines = $configParameters.Machines | ? { ( $_.Roles -contains "SearchQuery" ) -or ( $_.Roles -contains "SingleServerFarm" ) } | % { $_.Name }
    $SearchCrawlerMachines = $configParameters.Machines | ? { ( $_.Roles -contains "SearchCrawl" ) -or ( $_.Roles -contains "SingleServerFarm" ) } | % { $_.Name }
    $SPVersion = $configParameters.SPVersion;
    $DBServer = $configParameters.SPDatabaseServer;
    if ( !$DBServer -or ( $DBServer -eq "" ) )
    {
        $DBServer = $null;
        $configParameters.Machines | ? { $_.Roles -contains "SQL" } | % { if ( !$DBServer ) { $DBServer = $_.Name } }
    }
    
    if ( !$GranularApplying -or !$SearchTopologyGranule )
    {
        Node $SPMachines
        {

            <#
            LocalConfigurationManager
            {
                RebootNodeIfNeeded = $true;
            }
            #>

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
                ServerName  = $DBServer
            }

            $machineParameters = $configParameters.Machines | ? { $_.Name -eq $NodeName }
            $isWFE = ( $machineParameters.Roles -contains "WFE" ) -or ( $machineParameters.Roles -contains "SingleServerFarm" )
            $isApplication = ( $machineParameters.Roles -contains "Application" ) -or ( $machineParameters.Roles -contains "SingleServerFarm" )
            $isDCNode = ( $machineParameters.Roles -contains "DistributedCache" ) -or ( $machineParameters.Roles -contains "SingleServerFarm" )
            $isSearchQuery = ( $machineParameters.Roles -contains "SearchQuery" ) -or ( $machineParameters.Roles -contains "SingleServerFarm" )
            $isSearchCrawl = ( $machineParameters.Roles -contains "SearchCrawl" ) -or ( $machineParameters.Roles -contains "SingleServerFarm" )
            
            if ( $SPVersion -eq "2016" )
            {
                # possible serverroles: Application, ApplicationWithSearch, Custom, DistributedCache, Search, SingleServer, SingleServerFarm, WebFrontEnd, WebFrontEndWithDistributedCache
                $serverRole = $null;
                if ( $isWFE -and !$isApplication -and !$isDCNode -and !( $isSearchQuery -or $isSearchCrawl ) ) { $serverRole = "WebFrontEnd" }
                if ( !$isWFE -and !$isApplication -and $isDCNode -and !( $isSearchQuery -or $isSearchCrawl ) ) { $serverRole = "DistributedCache" }
                if ( $isWFE -and !$isApplication -and $isDCNode -and !( $isSearchQuery -or $isSearchCrawl ) ) { $serverRole = "WebFrontEndWithDistributedCache" }
                if ( !$isWFE -and $isApplication -and !$isDCNode -and !( $isSearchQuery -or $isSearchCrawl ) ) { $serverRole = "Application" }
                if ( !$isWFE -and !$isApplication -and !$isDCNode -and ( $isSearchQuery -or $isSearchCrawl ) ) { $serverRole = "Search" }
                if ( !$isWFE -and $isApplication -and !$isDCNode -and ( $isSearchQuery -or $isSearchCrawl ) ) { $serverRole = "ApplicationWithSearch" }
                if ( !$serverRole ) { $serverRole = "SingleServerFarm" }
                
                SPFarm Farm
                {
                    Ensure                    = "Present"
                    DatabaseServer            = $configParameters.SPDatabaseAlias
                    FarmConfigDatabaseName    = "SP_Config"
                    AdminContentDatabaseName  = "SP_AdminContent"
                    Passphrase                = $SPPassphraseCredential
                    FarmAccount               = $SPFarmAccountCredential
                    RunCentralAdmin           = $isWFE
                    CentralAdministrationPort = 50555
                    ServerRole                = "SingleServerFarm"
                    PsDscRunAsCredential      = $SPInstallAccountCredential
                    DependsOn                 = @( "[xSQLServerAlias]SPDBAlias" )
                }

            }
            if ( $SPVersion -eq "2013" )
            {
                SPFarm Farm
                {
                    Ensure                    = "Present"
                    DatabaseServer            = $configParameters.SPDatabaseAlias
                    FarmConfigDatabaseName    = "SP_Config"
                    AdminContentDatabaseName  = "SP_AdminContent"
                    Passphrase                = $SPPassphraseCredential
                    FarmAccount               = $SPFarmAccountCredential
                    RunCentralAdmin           = $isWFE
                    CentralAdministrationPort = 50555
                    PsDscRunAsCredential      = $SPInstallAccountCredential
                    DependsOn                 = @( <#"[xCredSSP]CredSSPServer", "[xCredSSP]CredSSPClient",#> "[xSQLServerAlias]SPDBAlias" )
                }

                if ( $isWFE -or $isApplication -or $isSearchCrawl )
                {

                    SPServiceInstance SharePointFoundationWebApplication
                    {
                        Name                    = "Microsoft SharePoint Foundation Web Application"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                }
                if ( $isWFE -or $isApplication )
                {

                    SPServiceInstance AppManagementService
                    {
                        Name                    = "App Management Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance BusinessDataConnectivityService
                    {
                        Name                    = "Business Data Connectivity Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance Claims2WindowsTokenService
                    {
                        Name                    = "Claims to Windows Token Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance MachineTranslationService
                    {
                        Name                    = "Machine Translation Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance ManagedMetadataServiceInstance
                    {
                        Name                    = "Managed Metadata Web Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance SubscriptionSettingsService
                    {
                        Name                    = "Microsoft SharePoint Foundation Subscription Settings Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance RequestManagement
                    {
                        Name                    = "Request Management"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance SecureStoreService
                    {
                        Name                    = "Secure Store Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance UserProfileService
                    {
                        Name                    = "User Profile Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                }
                if ( $isWFE )
                {

                    SPServiceInstance AccessDatabaseService2010
                    {
                        Name                    = "Access Database Service 2010"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance AccessServices
                    {
                        Name                    = "Access Services"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance ExcelCalculationServices
                    {
                        Name                    = "Excel Calculation Services"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance SandboxedCodeService
                    {
                        Name                    = "Microsoft SharePoint Foundation Sandboxed Code Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance PerformancePointService
                    {
                        Name                    = "PerformancePoint Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance VisioGraphicsService
                    {
                        Name                    = "Visio Graphics Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                }
                if ( $isDCNode )
                {

                    SPDistributedCacheService EnableDistributedCache
                    {
                        Name                    = "AppFabricCachingService"
                        CacheSizeInMB           = 2048
                        ServiceAccount          = $SPServicesAccountCredential.UserName
                        ServerProvisionOrder    = $DistributedCacheMachines
                        CreateFirewallRules     = $true
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = "[SPFarm]Farm"
                    }

                }
                if ( $isApplication )
                {

                    SPServiceInstance WordAutomationServices
                    {
                        Name                    = "Word Automation Services"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance WorkflowTimerService
                    {
                        Name                    = "Microsoft SharePoint Foundation Workflow Timer Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                }
                if ( $isSearchQuery -or $isSearchCrawl )
                {

                    SPServiceInstance SearchHostControllerService
                    {
                        Name                    = "Search Host Controller Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance SearchQueryandSiteSettingsService
                    {
                        Name                    = "Search Query and Site Settings Service"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                    SPServiceInstance SharePointServerSearch
                    {
                        Name                    = "SharePoint Server Search"
                        PsDscRunAsCredential    = $SPInstallAccountCredential
                        DependsOn               = @( "[SPFarm]Farm" )
                    }

                }
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

        }

        Node $ApplicationMachines
        {

            SPDiagnosticLoggingSettings ApplyDiagnosticLogSettings
            {
                LogPath                 = "$logFolder\ULS"
                LogSpaceInGB            = 10
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = @( "[SPFarm]Farm" )
            }

            SPManagedAccount ApplicationWebPoolAccount
            {
                AccountName             = $SPWebAppPoolAccountCredential.UserName
                Account                 = $SPWebAppPoolAccountCredential
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = @( "[SPFarm]Farm" )
            }

            SPWebApplication RootWebApp
            {
                Name                    = "RootWebApp"
                ApplicationPool         = "All Web Application"
                ApplicationPoolAccount  = $SPWebAppPoolAccountCredential.UserName
                Url                     = "http://$webAppHostName"
                DatabaseName            = "SP_Content_01"
                AuthenticationMethod    = "NTLM"
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPManagedAccount]ApplicationWebPoolAccount"
            }

            if ( $SPVersion -eq "20130" )
            {
                SPContentDatabase ContentDB
                {
                    Name                 = "SP_Content_01"
                    WebAppUrl            = "http://$webAppHostName"
                    PsDscRunAsCredential = $SPInstallAccountCredential
                }
            }
            
            SPCacheAccounts CacheAccounts
            {
                WebAppUrl               = "http://$webAppHostName"
                SuperUserAlias          = "$shortDomainName\$($configParameters.SPOCSuperUser)"
                SuperReaderAlias        = "$shortDomainName\$($configParameters.SPOCSuperReader)"
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPWebApplication]RootWebApp"
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
                PsDscRunAsCredential   = $SPInstallAccountCredential
                DependsOn              = "[SPCacheAccounts]CacheAccounts"
            }

            SPSite RootPathSite
            {
                Url                     = "http://$webAppHostName"
                OwnerAlias              = $SPInstallAccountCredential.UserName
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPWebApplication]RootWebApp"
            }

            SPSite RootHostSite
            {
                Url                         = "http://$SPSiteCollectionHostName"
                OwnerAlias                  = $SPInstallAccountCredential.UserName
                Template                    = "STS#0"
                HostHeaderWebApplication    = "http://$webAppHostName"
                PsDscRunAsCredential        = $SPInstallAccountCredential
                DependsOn                   = "[SPSite]RootPathSite"
            }
            
            SPManagedAccount SharePointServicesPoolAccount
            {
                AccountName             = $SPServicesAccountCredential.UserName
                Account                 = $SPServicesAccountCredential
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPFarm]Farm"
            }

            SPServiceAppPool SharePointServicesAppPool
            {
                Name                    = "SharePoint Services App Pool"
                ServiceAccount          = $SPServicesAccountCredential.UserName
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPManagedAccount]SharePointServicesPoolAccount"
            }

            SPAccessServiceApp AccessServices
            {
                Name                    = "Access Services"
                ApplicationPool         = "SharePoint Services App Pool";
                DatabaseServer          = $configParameters.SPDatabaseAlias
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPServiceAppPool]SharePointServicesAppPool"
            }

            SPBCSServiceApp BCSServiceApp
            {
                Name                    = "Business Data Connectivity Service"
                ApplicationPool         = "SharePoint Services App Pool";
                DatabaseServer          = $configParameters.SPDatabaseAlias
                DatabaseName            = "SP_BCS"
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPServiceAppPool]SharePointServicesAppPool"
            }

            SPManagedMetaDataServiceApp ManagedMetadataServiceApp
            {
                DatabaseName            = "SP_Metadata";
                ApplicationPool         = "SharePoint Services App Pool";
                ProxyName               = "Managed Metadata Service Application";
                Name                    = "Managed Metadata Service Application";
                Ensure                  = "Present";
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPServiceAppPool]SharePointServicesAppPool"
            }

            SPPerformancePointServiceApp PerformancePoint
            {
                Name                    = "PerformancePoint Service Application"
                ApplicationPool         = "SharePoint Services App Pool";
                DatabaseName            = "SP_PerformancePoint"
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPServiceAppPool]SharePointServicesAppPool"
            }

            SPSecureStoreServiceApp SecureStoreServiceApp
            {
                Name                    = "Secure Store Service"
                ApplicationPool         = "SharePoint Services App Pool"
                AuditingEnabled         = $true
                DatabaseName            = "SP_SecureStoreService"
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPServiceAppPool]SharePointServicesAppPool"
            }

            SPStateServiceApp StateServiceApp
            {
                Name                    = "State Service"
                DatabaseName            = "SP_StateService"
                Ensure                  = "Present"
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPServiceAppPool]SharePointServicesAppPool"
            }

            SPSubscriptionSettingsServiceApp SubscriptionSettingsServiceApp
            {
                Name                    = "Subscription Settings Service Application"
                ApplicationPool         = "SharePoint Services App Pool"
                DatabaseName            = "SP_SubscriptionSettings"
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPServiceAppPool]SharePointServicesAppPool"
            }

            SPAppManagementServiceApp AppManagementServiceApp
            {
                Name                    = "App Management Service Application"
                ApplicationPool         = "SharePoint Services App Pool"
                DatabaseName            = "SP_AppManagement"
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPSubscriptionSettingsServiceApp]SubscriptionSettingsServiceApp"
            }

            SPUsageApplication UsageApplication 
            {
                Name                    = "Usage Service Application"
                DatabaseName            = "SP_Usage"
                UsageLogCutTime         = 5
                UsageLogLocation        = "$logFolder\Usage"
                UsageLogMaxFileSizeKB   = 1024
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPServiceAppPool]SharePointServicesAppPool"
            }

            SPSite SearchCenterSite
            {
                Url                         = "http://$SPSiteCollectionHostName/sites/searchcenter"
                OwnerAlias                  = $SPInstallAccountCredential.UserName
                Template                    = "SRCHCEN#0"
                HostHeaderWebApplication    = "http://$webAppHostName"
                PsDscRunAsCredential        = $SPInstallAccountCredential
                DependsOn                   = "[SPSite]RootPathSite"
            }

            SPSite MySite
            {
                Url                         = "http://$SPSiteCollectionHostName/sites/my"
                OwnerAlias                  = $SPInstallAccountCredential.UserName
                Template                    = "SPSMSITEHOST#0"
                HostHeaderWebApplication    = "http://$webAppHostName"
                PsDscRunAsCredential        = $SPInstallAccountCredential
                DependsOn                   = "[SPSite]RootPathSite"
            }

            SPUserProfileServiceApp UserProfileServiceApp
            {
                Name                    = "User Profile Service Application"
                ApplicationPool         = "SharePoint Services App Pool"
                MySiteHostLocation      = "http://$SPSiteCollectionHostName/sites/my"
                ProfileDBName           = "SP_UserProfiles"
                SocialDBName            = "SP_Social"
                SyncDBName              = "SP_ProfileSync"
                EnableNetBIOS           = $false
                FarmAccount             = $SPFarmAccountCredential
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = @("[SPServiceAppPool]SharePointServicesAppPool","[SPSite]MySite")
            }

            SPVisioServiceApp VisioServices
            {
                Name                    = "Visio Graphics Service"
                ApplicationPool         = "SharePoint Services App Pool"
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPServiceAppPool]SharePointServicesAppPool"
            }

            SPWordAutomationServiceApp WordAutomation
            { 
                Name                    = "Word Automation Service" 
                Ensure                  = "Present"
                ApplicationPool         = "SharePoint Services App Pool"
                DatabaseName            = "SP_WordAutomation"
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPServiceAppPool]SharePointServicesAppPool"
            }

        }

        Node $SearchQueryMachines
        {

            File IndexFolder
            {
                DestinationPath = $searchIndexDirectory
                Type            = "Directory"
            }

        }
    }
    if ( !$GranularApplying -or $SearchTopologyGranule )
    {
        Node $SearchQueryMachines
        {

            SPManagedAccount SharePointSearchServicePoolAccount
            {
                AccountName             = $SPSearchServiceAccountCredential.UserName
                Account                 = $SPSearchServiceAccountCredential
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPFarm]Farm"
            }

            SPServiceAppPool SharePointSearchServiceAppPool
            {
                Name                    = "SharePoint Search App Pool"
                ServiceAccount          = $SPSearchServiceAccountCredential.UserName
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPManagedAccount]SharePointSearchServicePoolAccount"
            }

            SPSearchServiceApp SearchServiceApp
            {  
                Name                    = "Search Service Application"
                DatabaseName            = "SP_Search"
                ApplicationPool         = "SharePoint Search App Pool"
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPServiceAppPool]SharePointSearchServiceAppPool"
            }

            if ( !$GranularApplying ) {

                WaitForAll AllServersJoined
                {
                    ResourceName      = '[SPFarm]Farm'
                    NodeName          = $SearchMachines
                    RetryIntervalSec  = 15
                    RetryCount        = 300
                    DependsOn         = "[SPFarm]Farm"
                }

                WaitForAll FolderCreated
                {
                    ResourceName      = '[File]IndexFolder'
                    NodeName          = $SearchQueryMachines
                    RetryIntervalSec  = 15
                    RetryCount        = 300
                    DependsOn         = "[File]IndexFolder"
                }

                $topologyDependsOn = @( "[WaitForAll]AllServersJoined", "[WaitForAll]FolderCreated", "[SPSearchServiceApp]SearchServiceApp" )
            } else {
                $topologyDependsOn = @( "[SPSearchServiceApp]SearchServiceApp" )
            }

            SPSearchTopology LocalSearchTopology
            {
                ServiceAppName          = "Search Service Application"
                Admin                   = $SearchQueryMachines
                Crawler                 = $SearchCrawlerMachines
                ContentProcessing       = $SearchCrawlerMachines
                AnalyticsProcessing     = $SearchCrawlerMachines
                QueryProcessing         = $SearchQueryMachines
                PsDscRunAsCredential    = $SPInstallAccountCredential
                FirstPartitionDirectory = $searchIndexDirectory
                IndexPartition          = $SearchQueryMachines
                DependsOn               = $topologyDependsOn
            }

        }
    }
}
