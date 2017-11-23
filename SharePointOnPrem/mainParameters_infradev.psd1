@{
    Machines = @(
        @{
            Name = "SP16infrdev1ad1"
            Roles = "AD"
            Memory = 1.5
            DiskSize = 30
            WinVersion = "2016"
            Image = "Win2016ADV001"
        }
        @{
            Name = "SP16infrdev1sq1"
            Roles = "SQL"
            Memory = 14
            DiskSize = 120
            DataDisks = 50,50,50,200,50,100
            WinVersion = "2016"
            Image = ""
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
}