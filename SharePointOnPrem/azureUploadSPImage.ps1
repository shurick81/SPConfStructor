
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=2)]
    [string]$azureParametersFileName
)

Get-Date
$defaultAzureParameters = Import-PowershellDataFile "azureParameters.psd1";
if ( $systemParametersFileName )
{
    $difAzureParameters = Import-PowershellDataFile $azureParametersFileName;
    $azureParameters = .\combineparameters.ps1 $defaultAzureParameters, $difAzureParameters;
} else {
    $azureParameters = $defaultAzureParameters;
}
$resourceGroupName = $azureParameters.ResourceGroupName;
$resourceGroupLocation = $azureParameters.ResourceGroupLocation;
$imageResourceGroupName = $azureParameters.ImageResourceGroupName;
if ( !$imageResourceGroupName -or ( $imageResourceGroupName -eq "" ) )
{
    $imageResourceGroupName = $resourceGroupName;
}
$imageStorageAccountName = $azureParameters.ImageStorageAccount
$containerName = $azureParameters.SPImageAzureContainerName;

$subscription = $null;
$subscription = Get-AzureRmSubscription;
if ( !$subscription )
{
    Write-Host "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
    Write-Host "||||||||||||||||||Don't worry about this error above||||||||||||||||||"
    Login-AzureRmAccount | Out-Null;
}

$imageResourceGroup = $null;
$imageResourceGroup = Get-AzureRmResourceGroup $imageResourceGroupName -ErrorAction SilentlyContinue;
if ( !$imageResourceGroup )
{
    New-AzureRmResourceGroup -Name $imageResourceGroupName -Location $resourceGroupLocation | Out-Null;                
}
$imageStorageAccount = $null;
$imageStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $imageResourceGroupName -Name $imageStorageAccountName -ErrorAction SilentlyContinue;
if ( !$imageStorageAccount )
{
    New-AzureRmStorageAccount -ResourceGroupName $imageResourceGroupName -Name $imageStorageAccountName -Location $resourceGroupLocation `
    -SkuName "Standard_LRS" -Kind "Storage" | Out-Null;
}
Set-AzureRmCurrentStorageAccount -StorageAccountName $imageStorageAccountName -ResourceGroupName $azureParameters.ImageResourceGroupName;
$existingStorageContainer = $null;
$existingStorageContainer = Get-AzureStorageContainer $containerName -ErrorAction SilentlyContinue;
if ( !$existingStorageContainer )
{
    New-AzureStorageContainer -Name $containerName -Permission Off | Out-Null;
}
Set-AzureStorageBlobContent -Container $containerName -File "$($azureParameters.ImageLocalFolder)\$($azureParameters.SPImageFileName)" -Force | Out-Null;
Get-Date
