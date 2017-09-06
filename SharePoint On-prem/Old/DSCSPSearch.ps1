Configuration SPSearch
{
    param(
        $configParameters
    )
    $DomainName = $configParameters.DomainName;
    $SPInstallAccountUserName = $configParameters.SPInstallAccountUserName;
    $SPSearchServiceAccountUserName = $configParameters.SPSearchServiceAccountUserName;
    $SPCrawlerAccountUserName = $configParameters.SPCrawlerAccountUserName;
    $searchIndexDirectory = $configParameters.searchIndexDirectory;
    $SPSiteCollectionHostName = $configParameters.SPSiteCollectionHostName;

    $shortDomainName = $DomainName.Substring( 0, $DomainName.IndexOf( "." ) );
    $webAppHostName = "SP2013_01.$DomainName";

    # examining, generating and requesting credentials

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
    Import-DSCResource -ModuleName SharePointDSC

    $SearchQueryMachines = $configParameters.Machines | ? { $_.Roles -contains "SearchQuery" } | % { $_.Name }
    $SearchCrawlerMachines = $configParameters.Machines | ? { $_.Roles -contains "SearchCrawl" } | % { $_.Name }
    
    Node $SearchQueryMachines
    {
        SPManagedAccount SearchServicePoolAccount
        {
            AccountName     = $SPSearchServiceAccountCredential.UserName
            Account         = $SPSearchServiceAccountCredential
            InstallAccount  = $SPInstallAccountCredential
        }

        SPServiceAppPool SearchServiceAppPool
        {
            Name            = "SharePoint Search App Pool"
            ServiceAccount  = $SPSearchServiceAccountCredential.UserName
            InstallAccount  = $SPInstallAccountCredential
            DependsOn       = "[SPManagedAccount]SearchServicePoolAccount"
        }

        SPSearchServiceApp EnterpriseSearchServiceApplication
        {
            Name                        = "Search Service Application"
            Ensure                      = "Present"
            ApplicationPool             = "SharePoint Search App Pool"
            SearchCenterUrl             = "http://$SPSiteCollectionHostName/sites/searchcenter/pages"
            DatabaseName                = "SP_Search"
            DefaultContentAccessAccount = $SPCrawlerAccountCredential
            InstallAccount              = $SPInstallAccountCredential
            DependsOn                   = "[SPServiceAppPool]SearchServiceAppPool"
        }

        # this is to be only applied after all the servers are in the farm and only after service application is created
        SPSearchTopology SearchTopology
        {
            ServiceAppName          = "Search Service Application"
            ContentProcessing       = $SearchCrawlerMachines
            AnalyticsProcessing     = $SearchCrawlerMachines
            IndexPartition          = $SearchQueryMachines
            Crawler                 = $SearchCrawlerMachines
            Admin                   = $SearchCrawlerMachines
            QueryProcessing         = $SearchQueryMachines
            FirstPartitionDirectory = $searchIndexDirectory
            InstallAccount          = $SPInstallAccountCredential
            DependsOn = "[SPSearchServiceApp]EnterpriseSearchServiceApplication";
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
    }
}
