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
$configParameters.Machines | % {
    $vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -VMName $_.Name;
    $networkInterfaceRef = $vm.NetworkProfile[0].NetworkInterfaces[0].id;
    $networkInterface = Get-AzureRmNetworkInterface | ? { $_.Id -eq $networkInterfaceRef }
    $pip = Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName | ? { $_.id -eq $networkInterface.IpConfigurations[0].PublicIpAddress.id }
    Write-Host "$($_.Name) $($pip.IpAddress)"
    if ( ( $_.Roles -contains "Code" ) -or ( $_.Roles -contains "Configuration" ) )
    {
        . .\Connect-Mstsc\Connect-Mstsc.ps1
        Connect-Mstsc -ComputerName $pip.IpAddress -User "$shortDomainName\$($configParameters.SPInstallAccountUserName)" -Password $configParameters.SPInstallAccountPassword
    }
}

Get-Date
