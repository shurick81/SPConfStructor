@{
    ImageResourceGroupName = "development"
    ImageStorageAccount = "development7950"
    #Where the SharePoint Image is located on your machine where you run the PowerShell script
    ImageLocalFolder = "D:\Install"
    ResourceGroupName = "SP2013Ent01"
    ResourceGroupLocation = "westeurope"
    LocalAdminUserName = "splocaladm"
    LocalAdminPassword = "123$%^qweRTY"

    DeleteResourceGroup = $true
    PrepareResourceGroup = $true
    PrepareMachines = $true
    PrepareMachinesAfterImage = $true
    ADInstall = $true
    #SQLImageSourceOptions: Public, Skip
    SQLImageSource = "Skip"
    SQLImageLocation = "C:\Install\SQLImage"
    SQLImageUnpack = $false
    SQLInstall = $false
    #SPImageSource options: Public, AzureBlob, Skip
    SPImageSource = "Skip"
    #Valid names start and end with a lower case letter or a number and has in betweena lower case letter, number or dash with no consecutive dashes and is 3 through 63 characters long.
    SPImageAzureContainerName = "sp2013withsp1msdn"
    SPImageFolderUNC = ""
    SPImageFileName = "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"
    SPImageLocation = "C:\Install\SPImage"
    SPImageUnpack = $false
    SPInstall = $true
    ConfigurationToolsInstallation = $false
    ADConfigure = $false
    JoinDomain = $false
    ConfigureSharePoint = $false
    ShutDownAfterProvisioning = $false

    SubnetIpAddress = "192.168.0.0"
    PauseBeforeImaging = $false
    AzureMachineSizes = @(
        @{ MinMemory = 0; Size = "Basic_A1" },
        @{ MinMemory = 1.75; Size = "Basic_A2" },
        @{ MinMemory = 3.5; Size = "Standard_D11_v2" },
        @{ MinMemory = 15; Size = "Standard_D12_v2" }
    )
}