[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=2)]
    [string]$azureParametersFileName = "azureParameters.psd1"
)

Get-Date
$azureParameters = Import-PowershellDataFile $azureParametersFileName;
$subscription = $null;
$subscription = Get-AzureRmSubscription;
if ( !$subscription )
{
    Write-Host "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
    Write-Host "||||||||||||||||||Don't worry about this error above||||||||||||||||||"
    Login-AzureRmAccount
}
$azureParameters = Import-PowershellDataFile azureParameters.psd1;
Remove-AzureRmResourceGroup -Name $azureParameters.ResourceGroupName -Force | Out-Null;
Get-Date
