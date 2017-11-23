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

$subscription = $null;
$subscription = Get-AzureRmSubscription;
if ( !$subscription )
{
    Write-Host "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
    Write-Host "||||||||||||||||||Don't worry about this error above||||||||||||||||||"
    Login-AzureRmAccount | Out-Null;
}
Remove-AzureRmResourceGroup -Name $azureParameters.ResourceGroupName -Force | Out-Null;
Get-Date
