Configuration SP2013AzureLoadingInstallationFiles
{
    param(
        $azureParameters,
        $azureStorageAccountKey
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName cAzureStorage

    Node $AllNodes.NodeName
    {

        cAzureStorage SPServerImageFile {
            Path                    = $azureParameters.SPImageLocation
            StorageAccountName      = $azureParameters.ImageStorageAccount
            StorageAccountContainer = $azureParameters.SPImageAzureContainerName
            StorageAccountKey       = $azureStorageAccountKey
        }

    }
}
