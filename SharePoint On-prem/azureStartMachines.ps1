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
    Login-AzureRmAccount
}
$configParameters.Machines | ? { $_.Roles -contains "AD" } | % {
    Start-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name;
}
$ADClientMachines = $configParameters.Machines | ? { $_.Roles -notcontains "AD" }
if ( $ADClientMachines )
{
    sleep 300;
    $ADClientMachines | % {
        Start-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name;
    }
}
Get-Date
