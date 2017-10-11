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
$DomainName = $configParameters.DomainName;
$shortDomainName = $DomainName.Substring( 0, $DomainName.IndexOf( "." ) );
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
$noADwasrunning = $false;
$configParameters.Machines | ? { $_.Roles -contains "AD" } | % {
    $vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $_.Name -Status
    $powerState = $vm.Statuses | ? { $_.Code -like "PowerState/*" }
    if ( $powerState.DisplayStatus -ne "VM running" )
    {
        Write-Host "Starting $($_.Name)"
        Start-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name;
        $noADwasrunning = $true;
    } else {
        Write-Host "$($_.Name) is already started"
    }
}
$ADClientMachines = $configParameters.Machines | ? { $_.Roles -notcontains "AD" }
if ( $ADClientMachines )
{
    if ( $noADwasrunning )
    {
        Write-Host "Let's wait 5 minutes to make sure that domain is up and running"
        sleep 300;
    }
    $ADClientMachines | % {
        $vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $_.Name -Status
        $powerState = $vm.Statuses | ? { $_.Code -like "PowerState/*" }
        if ( $powerState.DisplayStatus -ne "VM running" )
        {
            Write-Host "Starting $($_.Name)"
            Start-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name;
        } else {
            Write-Host "$($_.Name) is already started"
        }
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
