@{
    ImageResourceGroupName = "development"
    ImageStorageAccount = "development7950"
    #Where the SharePoint Image is located on your machine where you run the PowerShell script
    ImageLocalFolder = "D:\Install"
    ResourceGroupName = "SPADImage2"
    ResourceGroupLocation = "westeurope"
    LocalAdminUserName = "splocaladm"
    LocalAdminPassword = "123$%^qweRTY"

    DeleteResourceGroup = $false
    PrepareResourceGroup = $true
    PrepareMachines = $true
    ADInstall = $true
    SQLImageSource = "Public"
    SQLImageLocation = "C:\Install\SQLImage"
    SQLImageUnpack = $false
    SQLInstall = $false
    SPImageSource = "Public"
    #Valid names start and end with a lower case letter or a number and has in betweena lower case letter, number or dash with no consecutive dashes and is 3 through 63 characters long.
    SPImageAzureContainerName = "sp2013withsp1msdn"
    SPImageFolderUNC = ""
    SPImageFileName = "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"
    SPImageLocation = "C:\Install\SPImage"
    SPImageUnpack = $false
    SPServicePackSource = "Skip"
    SPCumulativeUpdateSource = "Skip"
    SPInstall = $false
    ConfigurationToolsInstallation = $false
    ADConfigure = $true
    JoinDomain = $true
    ConfigureSharePoint = $false
    ShutDownAfterProvisioning = $false

    SubnetIpAddress = "192.168.0.0"
    PauseBeforeImaging = $true
}