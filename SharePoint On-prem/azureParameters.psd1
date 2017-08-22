@{
    ResourceGroupName = "SP2013Ent01"
    ResourceGroupLocation = "westeurope"
    LocalAdminUserName = "splocaladmin"
    LocalAdminPassword = "123$%^qweRTY"
    AzureAutomationPassword = "123$%^qweRTY"
    SubnetIpAddress = "192.168.0.0"
    DomainControllerIP = "192.168.0.4"

    Login = $false
    DeleteResourceGroup = $false
    PrepareResourceGroup = $false
    CreateVMs = $false
    DownloadInstallationFiles = $true
    PrepareSoftware = $false
    InstallDomain = $false
    JoinDomain = $false
    ConfigureSharePoint = $false
}