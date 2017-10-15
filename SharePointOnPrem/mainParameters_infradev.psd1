@{
    SPVersion = "2016"
    #Refer to https://github.com/brianlala/AutoSPSourceBuilder/blob/master/AutoSPSourceBuilder.xml for selecting a correct CU name
    SPCumulativeUpdate = "September 2017" #must not be empty
    SPLanguagePacks = "ru-ru,sv-se,nb-no" #must not be empty
    DomainName = "sp.local"
    #machine name restriction: 15 characters, ^[a-z][a-z0-9-]{1,61}[a-z0-9]$
    #roles: AD, SQL, SharePoint, WFE, Application, DistributedCache, SearchQuery, SearchCrawl, SingleServerFarm, OOS, WFM, Addins, Admin, Code, Client, Configuration
    #SP 2013 software requirements: https://technet.microsoft.com/en-us/library/cc262485.aspx?f=255&MSPPError=-2147217396
    # WinVersion options: "2016", "2012R2", "2012"
    #ProvisioninngType options: Image, Url, Manual
    Machines = @(
        @{
            Name = "SP16infrdev1ad1"
            Roles = "AD"
            Memory = 1.5
            DiskSize = 30
            WinVersion = "2016"
            Image = "Win2016AD"
        }
        @{
            Name = "SP16infrdev1sq1"
            Roles = "SQL"
            Memory = 14
            DiskSize = 120
            WinVersion = "2016"
            Image = "Win2016SQL2016"
        }
        @{
            Name = "SP16infrdev1sp1"
            Roles = "SharePoint", "WFE", "DistributedCache"
            Memory = 14
            DiskSize = 120
            WinVersion = "2016"
            Image = "Win2016SP2016CU201709EnRuSwNo"
        }
        @{
            Name = "SP16infrdev1sp2"
            Roles = "SharePoint", "SearchQuery"
            Memory = 14
            DiskSize = 120
            WinVersion = "2016"
            Image = "Win2016SP2016CU201709EnRuSwNo"
        }
        @{
            Name = "SP16infrdev1sp3"
            Roles = "SharePoint", "Application", "SearchCrawl"
            Memory = 14
            DiskSize = 120
            WinVersion = "2016"
            Image = "Win2016SP2016CU201709EnRuSwNo"
        }
        @{
            Name = "SP16infrdev1cl1"
            Roles = "Configuration"
            Memory = 1.5
            DiskSize = 30
            WinVersion = "10"
            Image = "Win10Conf"
        }
    )
    SPSiteCollectionHostName = "SP16infrdev1sp1.westeurope.cloudapp.azure.com"
    SearchIndexDirectory = "c:\SPSearchIndex"
    SPProductKey = ""
    DomainAdminUserName = "dauser1"
    DomainAdminPassword = "123$%^qweRTY"
    DomainSafeModeAdministratorPassword = "123$%^qweRTY"
    SPInstallAccountUserName = "_spadm"
    SPInstallAccountPassword = "123$%^qweRTY"
    SPFarmAccountUserName = "_spfrm"
    SPFarmAccountPassword = "123$%^qweRTY"
    SPWebAppPoolAccountUserName = "_spwebapppool"
    SPWebAppPoolAccountPassword = "123$%^qweRTY"
    SPServicesAccountUserName = "_spsrv"
    SPServicesAccountPassword = "123$%^qweRTY"
    SPSearchServiceAccountUserName = "_spsrchsrv"
    SPSearchServiceAccountPassword = "123$%^qweRTY"
    SPCrawlerAccountUserName = "_spcrawler"
    SPCrawlerAccountPassword = "123$%^qweRTY"
    SPTestAccountUserName = "_sptestuser1"
    SPTestAccountPassword = "123$%^qweRTY"
    SPSecondTestAccountUserName = "_sptestuser2"
    SPSecondTestAccountPassword = "123$%^qweRTY"
    SPOCSuperUser = "_spocuser"
    SPOCSuperReader = "_spocrdr"
    SPAdminGroupName = "SP Admins"
    SPMemberGroupName = "SP Members"
    SPVisitorGroupName = "SP Visitors"
    SQLAdminGroupName = "SQL Admins"
    SPPassphrase = "123$%^qweRTY"
    SQLPass = "P@ssw0rd"
    SPDatabaseAlias = "SPDB"
    SPDatabaseServer = ""
    SQLInstallationMediaPath = "C:\Install\SQLMedia"
    SPInstallationMediaPath = "C:\Install\SPInstall"
    SSMSInstallationFolderPath = "C:\Install\SSMS"
    SSMSVersion = "17.2"
    SPLogFolder = "C:\SPLogs"
    VSVersion = "Professional"

    SPLanguage = "English" #don't use
    SPServicePack = "SP1" #don't use
    SPMultitenancy = $false #don't use
}