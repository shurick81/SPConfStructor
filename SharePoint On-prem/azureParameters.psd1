@{
    ImageResourceGroupName = "development"
    ImageStorageAccount = "development7950"
    #Where the SharePoint Image is located on your machine where you run the PowerShell script
    ImageLocalFolder = "D:\Install"
    ResourceGroupName = "SP2016Ent01"
    ResourceGroupLocation = "westeurope"
    LocalAdminUserName = "splocaladm"
    LocalAdminPassword = "123$%^qweRTY"
    AzureAutomationPassword = "123$%^qweRTY"
    SubnetIpAddress = "192.168.0.0"
    DomainControllerIP = "192.168.0.4"

    DeleteResourceGroup = $true
    PrepareResourceGroup = $true
    CreateVMs = $true
    PrepareMachines = $true
    ADInstall = $true
    SQLImageSource = "Public"
    SQLImageLocation = "C:\Install\SQLImage"
    SQLImageUnpack = $true
    SQLInstall = $true
    SPImageSource = "Public"
    #Valid names start and end with a lower case letter or a number and has in betweena lower case letter, number or dash with no consecutive dashes and is 3 through 63 characters long.
    SPImageAzureContainerName = "sp2013withsp1msdn"
    SPImageFolderUNC = ""
    SPImageFileName = "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"
    SPImageLocation = "C:\Install\SPImage"
    SPImageUnpack = $true
    SPServicePackSource = "Skip"
    SPCumulativeUpdateSource = "Skip"
    SPInstall = $true
    ADConfigure = $true
    JoinDomain = $true
    ConfigurationToolsInstallation = $true
    ConfigureSharePoint = $true

    <#
    ImagePreparationOptions = @{
        PrepareMachines = $true
        ADInstall = $true
        #SQLImageSource options: Public, AzureBlob, ManualCopy, Skip
        SQLImageSource = "Public"
        SQLImageLocation = "C:\Install\SQLImage"
        SQLImageUnpack = $true
        SQLInstall = $true
        SPImageSource = "AzureBlob"
        #Valid names start and end with a lower case letter or a number and has in betweena lower case letter, number or dash with no consecutive dashes and is 3 through 63 characters long.
        SPImageAzureContainerName = "sp2013withsp1msdn"
        SPImageFileName = "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"
        SPImageLocation = "C:\Install\SPImage"
        SPImageUnpack = $true
        SPServicePackSource = "Skip"
        SPCumulativeUpdateSource = "Skip"
        SPInstall = $true
    }
    #>

    
}