@{
    SPVersion = "2013"
    SPServicePack = "SP1"
    SPCumulativeUpdate = ""
    SPLanguage = "English"
    SPLanguagePacks = @("Swedish")
    SPServices = @{
        AccessService2010 = $true
        AccessService = $true
    }
    SPMultitenancy = $false
    DomainName = "sharepoint.local"
    #machine name restriction: 15 characters, ^[a-z][a-z0-9-]{1,61}[a-z0-9]$
    #roles: AD, SQL, WFE, Application, DistributedCache, SearchQuery, SearchCrawl, OOS, WFM, Addins, Admin, Code, Client
    #SP 2013 software requirements: https://technet.microsoft.com/en-us/library/cc262485.aspx?f=255&MSPPError=-2147217396
    #Default WinVersion is 2016. other options: "2012", "2012R2"
    #ProvisioninngType options: Image, Url, Manual
    Machines = @(
        @{
            Name = "SP2013Ent01dc01"
            Roles = "AD"
            Memory = 1.5
            DiskSize = 30
            WinVersion = ""
            Image = ""
        }
        <#
        @{
            Name = "SP2013Ent01adm"
            Roles = "Admin"
            Memory = 1.5
            DiskSize = 30
            WinVersion = ""
            Image = ""
        }
        #>
        @{
            Name = "SP2013Ent01sq01"
            Roles = "SQL"
            Memory = 14
            DiskSize = 120
            WinVersion = "2016"
            Image = "W2016SQL2014wSP1"
        }
        @{
            Name = "SP2013Ent01sp01"
            Roles = "SharePoint", "WFE", "Application", "DistributedCache", "SearchQuery", "SearchCrawl", "Code"
            Memory = 14
            DiskSize = 120
            WinVersion = "2012"
            Image = "W2012SP2013wSP1"
        }
        <#
        @{
            Name = "SP2013Ent01cl01"
            Roles = "Client"
            Memory = 1.5
            DiskSize = 30
            WinVersion = "10"
            Image = ""
        }
        #>
    )
    SearchIndexDirectory = "c:\SPSearchIndex"
    SPProductKey = "NQTMW-K63MQ-39G6H-B2CH9-FRDWJ"
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