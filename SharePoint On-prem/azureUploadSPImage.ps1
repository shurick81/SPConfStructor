
[CmdletBinding()]
Param(	
    [Parameter(Mandatory=$False,Position=2)]
    [string]$azureParametersFileName = "azureParameters.psd1"
)

#Login-AzureRmAccount

Get-Date
$azureParameters = Import-PowershellDataFile $azureParametersFileName;

$containerName = $azureParameters.SPImageAzureContainerName;
$fileName = $azureParameters.SPImageFileName;
$subscriptionName = (Get-AzureRmSubscription)[0].Name;
Set-AzureRmCurrentStorageAccount -StorageAccountName $azureParameters.ImageStorageAccount -ResourceGroupName $azureParameters.ImageResourceGroupName;
$existingStorageContainer = $null;
$existingStorageContainer = Get-AzureStorageContainer $containerName -ErrorAction SilentlyContinue;
if ( !$existingStorageContainer )
{
    New-AzureStorageContainer -Name $containerName -Permission Off | Out-Null;
}
Set-AzureStorageBlobContent -Container $containerName -File "$($azureParameters.ImageLocalFolder)\$($azureParameters.SPImageFileName)" -Force | Out-Null;
Get-Date
