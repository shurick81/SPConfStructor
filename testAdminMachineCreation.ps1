$resourceGroupName = "SPCSadmintest"
$machineName = "SPCSadmintest"
$vnetName = "SPCSadmintestVN"
$resourceGroupLocation = "westeurope"
$VMuserName = "adminuser"
$VMpassword = "123$%^qweRTY"

$subscription = $null;
$subscription = Get-AzureRmSubscription;
if ( !$subscription )
{
    Write-Host "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
    Write-Host "||||||||||||||||||Don't worry about this error above||||||||||||||||||"
    Login-AzureRmAccount | Out-Null;
}

$resourceGroup = Get-AzureRmResourceGroup $resourceGroupName -ErrorAction Ignore;
if ( !$resourceGroup )
{
    $resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;
}

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName -ErrorAction Ignore;
if ( !$vnet )
{
    $SubnetIpAddress = "192.168.0.0";
    $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name ( $resourceGroupName + "Subnet" ) -AddressPrefix "$SubnetIpAddress/24";
    $vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -Name $vnetName -AddressPrefix "$SubnetIpAddress/16" -Subnet $subnetConfig;
}
$subnetId = $vnet.Subnets[0].Id;

$storageAccounts = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -ErrorAction Ignore;
if ( !$storageAccounts )
{
    $storageAccountNameLong = [guid]::NewGuid().Guid.Replace("-","");
    $storageAccountName = $storageAccountNameLong.Substring( 0, [System.Math]::Min( 24, $storageAccountNameLong.Length ) ).ToLower();
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $resourceGroupLocation `
        -SkuName "Standard_LRS" -Kind "Storage" | Out-Null;
}    

$publicIpName = ( $machineName + "IP" );
$pip = Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Name $publicIpName -ErrorAction Ignore;
if ( !$pip )
{
    $pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -AllocationMethod Dynamic -IdleTimeoutInMinutes 4 -Name $publicIpName;
}

$nsgName = ( $machineName + "-ngs")
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName -ErrorAction Ignore;
if ( !$nsg )
{
    $nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name RDP -Protocol Tcp `
        -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
        -DestinationPortRange 3389 -Access Allow;
    $nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -Name $nsgName -SecurityRules $nsgRuleRDP;
}

$nicName = ( $machineName + "NIC" )
$nic = Get-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName -Name $nicName -ErrorAction Ignore;
if ( !$nic )
{
    $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation `
        -SubnetId $subnetId -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
}

#Check machine sizes: Get-AzureRmVMSize -Location westeurope
$VMSize = "Basic_A1"
$publisherName = "MicrosoftWindowsDesktop"
$offer = "Windows-10";
$skus = "RS2-Pro"
$securedPassword = ConvertTo-SecureString $VMpassword -AsPlainText -Force
$vmCredential = New-Object System.Management.Automation.PSCredential( $VMuserName, $securedPassword )
$vmConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $VMSize | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName $machineName -Credential $vmCredential | `
    Set-AzureRmVMSourceImage -PublisherName $publisherName -Offer $offer -Skus $skus -Version latest | `
    Add-AzureRmVMNetworkInterface -Id $nic.Id
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -VM $vmConfig | Out-Null;

$vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -VMName $machineName;
$networkInterfaceRef = $vm.NetworkProfile[0].NetworkInterfaces[0].id;
$networkInterface = Get-AzureRmNetworkInterface | ? { $_.Id -eq $networkInterfaceRef }
$pip = Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName | ? { $_.id -eq $networkInterface.IpConfigurations[0].PublicIpAddress.id }
. .\Connect-Mstsc\Connect-Mstsc.ps1
Connect-Mstsc -ComputerName $pip.IpAddress -User "\$VMUserName" -Password $VMpassword

