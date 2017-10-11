[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=1)]
    [string]$mainParametersFileName = "mainParemeters.psd1",
	
    [Parameter(Mandatory=$False,Position=2)]
    [string]$azureParametersFileName = "azureParameters.psd1"
)

Get-Date
$configParameters = Import-PowershellDataFile $mainParametersFileName;
$azureParameters = Import-PowershellDataFile $azureParametersFileName;
$subscription = $null;
$subscription = Get-AzureRmSubscription;
if ( !$subscription )
{
    Write-Host "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
    Write-Host "||||||||||||||||||Don't worry about this error above||||||||||||||||||"
    Login-AzureRmAccount | Out-Null;
}
$configParameters.Machines | ? { $_.Roles -notcontains "AD" } | % {
    $vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $_.Name -Status
    $powerState = $vm.Statuses | ? { $_.Code -like "PowerState/*" }
    if ( $powerState.DisplayStatus -ne "VM stopped" )
    {
        Stop-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name -Force;
    }
}
$configParameters.Machines | ? { $_.Roles -contains "AD" } | % {
    $vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $_.Name -Status
    $powerState = $vm.Statuses | ? { $_.Code -like "PowerState/*" }
    if ( $powerState.DisplayStatus -ne "VM stopped" )
    {
        Stop-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name -Force;
    }
}
Get-Date
