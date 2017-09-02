Configuration SP2013
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
    $webAppHostName = "SP2013_01.$DomainName";

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xNetworking
    Import-DSCResource -ModuleName xSQLServer -Name xSQLServerAlias
    Import-DSCResource -ModuleName SharePointDSC

    $SPMachines = $configParameters.Machines | ? { $_.Roles -contains "SharePoint" } | % { $_.Name }
    $WFEMachines = $configParameters.Machines | ? { $_.Roles -contains "WFE" } | % { $_.Name }
    $ApplicationMachines = $configParameters.Machines | ? { $_.Roles -contains "Application" } | % { $_.Name }
    $DistributedCacheMachines = $configParameters.Machines | ? { $_.Roles -contains "DistributedCache" } | % { $_.Name }
    $SearchMachines = $configParameters.Machines | ? { ( $_.Roles -contains "SearchQuery" ) -or ( $_.Roles -contains "SearchCrawl" ) } | % { $_.Name }
    $SearchQueryMachines = $configParameters.Machines | ? { $_.Roles -contains "SearchQuery" } | % { $_.Name }
    $SearchCrawlerMachines = $configParameters.Machines | ? { $_.Roles -contains "SearchCrawl" } | % { $_.Name }

    if ( !$GranularApplying -or !$SearchTopologyGranule )
    {
        Node $SPMachines
        {

            LocalConfigurationManager
            {
                RebootNodeIfNeeded = $true;
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
                    
            xSQLServerAlias SPDBAlias
            {
                Ensure      = 'Present'
                Name        = $configParameters.SPDatabaseAlias
                ServerName  = $configParameters.SPDatabaseServer
            }

            <#
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
            #>

            $machineParameters = $configParameters.Machines | ? { $_.Name -eq $NodeName }
            $runCentralAdmin = $machineParameters.Roles -contains "WFE"
            SPFarm Farm
            {
                Ensure                    = "Present"
                DatabaseServer            = $configParameters.SPDatabaseAlias
                FarmConfigDatabaseName    = "SP_Config"
                AdminContentDatabaseName  = "SP_AdminContent"
                Passphrase                = $SPPassphraseCredential
                FarmAccount               = $SPFarmAccountCredential
                RunCentralAdmin           = $runCentralAdmin
                CentralAdministrationPort = 50555
                InstallAccount            = $SPInstallAccountCredential
                DependsOn                 = @( <#"[xCredSSP]CredSSPServer", "[xCredSSP]CredSSPClient",#> "[xSQLServerAlias]SPDBAlias" )
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

        Node $WFEMachines
        {

            #WFE service instances. Options: https://www.powershellgallery.com/packages/SharePointDSC/1.6.0.0/Content/DSCResources%5CMSFT_SPServiceInstance%5CMSFT_SPServiceInstance.psm1
            SPServiceInstance ManagedMetadataServiceInstance
            {
                Name                    = "Managed Metadata Web Service"
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = @( "[SPFarm]Farm" )
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
                PsDscRunAsCredential          = $SPInstallAccountCredential
                DependsOn               = "[SPManagedAccount]ApplicationWebPoolAccount"
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

        Node $DistributedCacheMachines
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
        
        #Search

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
                Name                    = "SharePoint Services App Pool"
                ServiceAccount          = $SPSearchServiceAccountCredential.UserName
                PsDscRunAsCredential    = $SPInstallAccountCredential
                DependsOn               = "[SPManagedAccount]SharePointSearchServicePoolAccount"
            }

            SPSearchServiceApp SearchServiceApp
            {  
                Name                    = "Search Service Application"
                DatabaseName            = "SP_Search"
                ApplicationPool         = "SharePoint Service Applications"
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
                }

                WaitForAll FolderCreated
                {
                    ResourceName      = '[File]IndexFolder'
                    NodeName          = $SearchQueryMachines
                    RetryIntervalSec  = 15
                    RetryCount        = 300
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
