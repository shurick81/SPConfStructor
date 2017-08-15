
$azureParameters = Import-PowershellDataFile azureParameters.psd1;
$configParameters = Import-PowershellDataFile mainParemeters.psd1;


$domainAdminUserName = $configParameters.DomainAdminUserName;
if ( !$DomainAdminCredential )
{
    if ( $domainAdminUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.DomainAdminPassword -AsPlainText -Force
        $domainAdminCredential = New-Object System.Management.Automation.PSCredential( "$domainAdminUserName", $securedPassword )
    } else {
        $domainAdminCredential = Get-Credential -Message "Credential with domain administrator privileges";
    }
}
$localAdminUserName = $azureParameters.LocalAdminUserName;
if ( !$LocalAdminCredential )
{
    if ( $localAdminUserName )
    {
        $securedPassword = ConvertTo-SecureString $azureParameters.LocalAdminPassword -AsPlainText -Force
        $localAdminCredential = New-Object System.Management.Automation.PSCredential( "$localAdminUserName", $securedPassword )
    } else {
        $localAdminCredential = Get-Credential -Message "Credential with local administrator privileges";
    }
}

#Login-AzureRmAccount

$resourceGroupName = $azureParameters.ResourceGroupName;
$resourceGroup = Get-AzureRmResourceGroup $resourceGroupName -ErrorAction Ignore;
if ( !$resourceGroup )
{
    $resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $azureParameters.ResourceGroupLocation;
}
$resourceGroupLocation = $resourceGroup.Location;
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name ( $resourceGroupName + "Subnet" ) -AddressPrefix 192.168.0.0/24;
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -Name ( $resourceGroupName + "VNet") -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig;
$subnetId = $vnet.Subnets[0].Id;

$storageAccountNameLong = ( $resourceGroupName + "StdStor" );
$storageAccountName = $storageAccountNameLong.Substring( 0, [System.Math]::Min( 24, $storageAccountNameLong.Length ) ).ToLower();
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $resourceGroupLocation `
    -SkuName "Standard_LRS" -Kind "Storage" | Out-Null;


$machineName = $configParameters.DCMachineName;

$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -AllocationMethod Dynamic -IdleTimeoutInMinutes 4 -Name ( $machineName + "IP" ) -DomainNameLabel $machineName.ToLower();

$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name RDP -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow;
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -Name ( $machineName + "-ngs") -SecurityRules $nsgRuleRDP;

$nic = New-AzureRmNetworkInterface -Name ( $machineName + "NIC" ) -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation `
    -SubnetId $subnetId -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

$vmConfig = New-AzureRmVMConfig -VMName $machineName -VMSize "Basic_A1" | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName $machineName -Credential $DomainAdminCredential | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -VM $vmConfig | Out-Null;

$machineName = $configParameters.SP2016EntDevMachineName

$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -AllocationMethod Dynamic -IdleTimeoutInMinutes 4 -Name ( $machineName + "IP" ) -DomainNameLabel $machineName.ToLower();

$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name RDP -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow;
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -Name ( $machineName + "-ngs") -SecurityRules $nsgRuleRDP;
$nsg | Add-AzureRmNetworkSecurityRuleConfig -Name Web -Protocol Tcp `
    -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 80 -Access Allow | Out-Null;
$nsg | Set-AzureRmNetworkSecurityGroup | Out-Null;

$nic = New-AzureRmNetworkInterface -Name ( $machineName + "NIC" ) -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation `
    -SubnetId $subnetId -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
    
$vmConfig = New-AzureRmVMConfig -VMName $machineName -VMSize D11_V2 | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName $machineName -Credential $localAdminCredential | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -VM $vmConfig | Out-Null;
#Start-AzureRmAutomationDscCompilationJob -ResourceGroupName "development" -AutomationAccountName "lab2-automation" -ConfigurationName "SharePointDevelopmentEnvironment" -ConfigurationData configurationdata.psd1 -Parameters $parameters