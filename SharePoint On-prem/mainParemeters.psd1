@{
    # 2013 or 2016:
    SPVersion = "2013"
    #For future use
    SPCU = "2017 April"
    #For future use
    SPLanguagePacks = @("Swedish")
    #For future use
    SPAccessServices = $true
    #For future use
    SPMultitenancy = $true
    DomainName = "SP2016Ent.local"
    #15 characters, ^[a-z][a-z0-9-]{1,61}[a-z0-9]$
    DCMachineName = "SP2016Entdc01"
    #15 characters, ^[a-z][a-z0-9-]{1,61}[a-z0-9]$
    SP2016EntDevMachineName = "SP2016Entsp01"
    #name restriction: 15 characters, ^[a-z][a-z0-9-]{1,61}[a-z0-9]$
    #2013 roles: AD, SQL, WFE, BATCH, DistributedCache, SearchQuery, SearchCrawl, OWA, WFM, Addins
    #2016 roles: AD, SQL, WFE, Application, DistributedCache, SearchQuery, SearchCrawl, OOS, WFM, Addins
    Machines = @(
        @{
            Name = "SP2013Ent01dc01"
            Roles = "AD"
            Memory = 1.5
            DiskSize = 30
        }
        @{
            Name = "SP2013Ent01sp01"
            Roles = "SQL", "WFE", "BATCH", "DistributedCache", "SearchQuery", "SearchCrawl"
            Memory = 14
            DiskSize = 120
        }
    )
    SubnetIpAddress = "192.168.0.0"
    DomainControllerIP = "192.168.0.4"
    SearchIndexDirectory = "c:\SPSearchIndex"
    SPProductKey = "NQGJR-63HC8-XCRQH-MYVCH-3J3QR"
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
    SPPassphrase = "123$%^qweRTY"
    SQLPass = "P@ssw0rd"
    SPDatabaseServer = "SP2013Ent01sp01"
    SPDatabaseAlias = "SPDB"
    SPSiteCollectionHostName = "SP2013Ent01sp01.westeurope.cloudapp.azure.com"
}