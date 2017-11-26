[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=1)]
    [string]$mainParametersFileName,
	
    [Parameter(Mandatory=$False,Position=2)]
    [string]$azureParametersFileName
)


Get-Date
$defaultMainParameters = Import-PowershellDataFile "mainParameters.psd1";
if ( $MainParametersFileName )
{
    $difMainParameters = Import-PowershellDataFile $MainParametersFileName;
    $configParameters = .\combineparameters.ps1 $defaultMainParameters, $difMainParameters
} else {
    $configParameters = $defaultMainParameters; 
}
$defaultAzureParameters = Import-PowershellDataFile "azureParameters.psd1";
if ( $azureParametersFileName )
{
    $difAzureParameters = Import-PowershellDataFile $azureParametersFileName;
    $azureParameters = .\combineparameters.ps1 $defaultAzureParameters, $difAzureParameters;
} else {
    $azureParameters = $defaultAzureParameters;
}
$resourceGroupName = $azureParameters.ResourceGroupName;
$subscription = $null;
$subscription = Get-AzureRmSubscription;
if ( !$subscription )
{
    Write-Host "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
    Write-Host "||||||||||||||||||Don't worry about this error above||||||||||||||||||"
    Login-AzureRmAccount | Out-Null;
}
$configParameters.Machines | ? { ( $_.Roles -notcontains "AD" ) -and ( $_.Roles -notcontains "SQL" ) } | % {
    $vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $_.Name -Status
    $powerState = $vm.Statuses | ? { $_.Code -like "PowerState/*" }
    if ( $powerState.DisplayStatus -ne "VM stopped" )
    {
        Stop-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name -Force;
    }
}
$configParameters.Machines | ? { ( $_.Roles -notcontains "AD" ) -and ( $_.Roles -contains "SQL" ) } | % {
    $vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $_.Name -Status
    $powerState = $vm.Statuses | ? { $_.Code -like "PowerState/*" }
    if ( $powerState.DisplayStatus -ne "VM stopped" )
    {
        Stop-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name -Force;
    }
}
$configParameters.Machines | ? { $_.Roles -contains "AD"  } | % {
    $vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $_.Name -Status
    $powerState = $vm.Statuses | ? { $_.Code -like "PowerState/*" }
    if ( $powerState.DisplayStatus -ne "VM stopped" )
    {
        Stop-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name -Force;
    }
}
Get-Date
