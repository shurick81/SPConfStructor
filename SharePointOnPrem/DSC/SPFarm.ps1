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
    $SPSiteCollectionHostName = $configParameters.SPSiteCollectionHostName;

    $shortDomainName = $DomainName.Substring( 0, $DomainName.IndexOf( "." ) );
    $webAppHostName = "SPWA_01.$DomainName";
    $DBServer = $configParameters.SPDatabaseServer;
    if ( !$DBServer -or ( $DBServer -eq "" ) )
    {
        $DBServer = $null;
        $configParameters.Machines | ? { $_.Roles -contains "SQL" } | % { if ( !$DBServer ) { $DBServer = $_.Name } }
    }

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xNetworking
    Import-DSCResource -ModuleName xSQLServer -Name xSQLServerAlias
    Import-DscResource -ModuleName xCredSSP
    Import-DSCResource -ModuleName SharePointDSC
    
    Node $AllNodes.NodeName
    {

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
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

        SPFarm Farm
        {
            Ensure                    = "Present"
            DatabaseServer            = $configParameters.SPDatabaseAlias
            FarmConfigDatabaseName    = "SP_Config"
            AdminContentDatabaseName  = "SP_AdminContent"
            Passphrase                = $SPPassphraseCredential
            FarmAccount               = $SPFarmAccountCredential
            RunCentralAdmin           = $true
            CentralAdministrationPort = 50555
            ServerRole                = "SingleServerFarm"
            PsDscRunAsCredential      = $SPInstallAccountCredential
            DependsOn                 = @( "[xCredSSP]CredSSPServer", "[xCredSSP]CredSSPClient", "[xSQLServerAlias]SPDBAlias" )
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
            WebAppUrl               = "http://$webAppHostName"
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

    }
}
