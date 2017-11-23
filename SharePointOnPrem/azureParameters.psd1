@{
    #Where the SharePoint Image is located on your machine where you run the PowerShell script
    ImageLocalFolder = "D:\Install"
    #disposable resource group for the environment
    ResourceGroupName = "SPConfStructorDev"
    DiskStorageAccount = "standarddisks"
    #keep in mind that there cannot be more than one image with the same name in one resource group
    ImageResourceGroupName = "sharedresourceswesteurope"
    ImageStorageAccount = "imageswesteurope"
    ResourceGroupLocation = "westeurope"
    LocalAdminUserName = "splocaladm"
    LocalAdminPassword = "123$%^qweRTY"

    DeleteResourceGroup = $false
    PrepareResourceGroup = $true
    PrepareMachines = $true
    PrepareMachinesAfterImage = $false
    ADInstall = $true
    #SQLMediaSource Options: Public, PreparedShare, Skip
    SQLMediaSource = "Public"
    SQLPreparedShare = "\\sapdevwe.file.core.windows.net\installmedia\SQL2014wSP1"
    MediaShareUserName = "not\empty"
    MediaSharePassword = "not empty"
    SQLImageLocation = "C:\Install\SQLImage"
    SQLImageUnpack = $true
    SQLInstall = $true
    #SPMediaSource options: Public, AzureBlobImage, PreparedShare, Skip
    SPMediaSource = "Public"
    #Valid names start and end with a lower case letter or a number and has in betweena lower case letter, number or dash with no consecutive dashes and is 3 through 63 characters long.
    SPImageAzureContainerName = "sp2013withsp1msdn"
    SPPreparedShare = "\\sapdevwe.file.core.windows.net\installmedia\SP2013wSP1CU201705EnRuSwNo"
    SPImageFolderUNC = ""
    SPImageFileName = "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"
    SPImageLocation = "C:\Install\SPImage"
    SPImageUnpack = $true
    SPInstall = $true
    CodeToolsInstallation = $true
    ConfigurationToolsInstallation = $true
    OfficeToolsInstallation = $true
    ADConfigure = $true
    JoinDomain = $true
    ConfigureSharePoint = $true
    UserToolsProvisioning = $true
    ShutDownAfterProvisioning = $false

    SubnetIpAddress = "192.168.0.0"
    PauseBeforeImaging = $false

    DefaultMachineSize = "Basic_A1"
    MachineSizes = @(
        @{ MinMemory = 1.8; Size = "Standard_DS1_v2" }
        @{ MinMemory = 3.6; Size = "Standard_DS2_v2" }
        @{ MinMemory = 8; Size = "Standard_DS11_v2" }
        @{ MinMemory = 15; Size = "Standard_DS12_v2" }
    )
    VMStorageAccountType = "StandardLRS"
}