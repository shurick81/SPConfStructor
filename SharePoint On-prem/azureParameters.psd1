@{
    ImageResourceGroupName = "development"
    ImageStorageAccount = "development7950"
    #Where the SharePoint Image is located on your machine where you run the PowerShell script
    ImageLocalFolder = "D:\Install"
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
    CreateVMs = $true
    DownloadInstallationFiles = $true
    InstallDomain = $false
    JoinDomain = $false
    ConfigureSharePoint = $false

    PrepareVMImages = $true
    ImagePreparationOptions = @{
        ADInstall = $false
        #SQLImageSource options: #Public, AzureBlob, ManualCopy
        SQLImageSource = "ManualCopy"
        SQLImageUnpack = $false
        SQLInstall = $false
        SPImageSource = "ManualCopy"
        SPImageUnpack = $false
        SPInstall = $true
        SPServicePackSource = "ManualCopy"
        SPCumulativeUpdateSource = "ManualCopy"
    }

    UseVMImages = $false
    ADInstall = $false
    SQLImageSource = "ManualCopy"
    SQLImageUnpack = $false
    SQLInstall = $false
    SPImageSource = "Public"
    #Valid names start and end with a lower case letter or a number and has in betweena lower case letter, number or dash with no consecutive dashes and is 3 through 63 characters long.
    SPImageAzureContainerName = "sp2013withsp1msdn"
    SPImageFileName = "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"
    SPImageUnpack = $true
    SPInstall = $true
    SPServicePackSource = "Public"
    SPCumulativeUpdateSource = "Public"

    SPImageUNC = ""
}