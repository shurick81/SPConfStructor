Get-Date
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

$vnetName = ( $resourceGroupName + "VNet");
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName -ErrorAction Ignore;
if ( !$vnet )
{
    $SubnetIpAddress = $configParameters.SubnetIpAddress;
    $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name ( $resourceGroupName + "Subnet" ) -AddressPrefix "$SubnetIpAddress/24";
    $vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -Name $vnetName -AddressPrefix "$SubnetIpAddress/16" -Subnet $subnetConfig;
}
$subnetId = $vnet.Subnets[0].Id;

$storageAccountNameLong = ( $resourceGroupName + "StdStor" );
$storageAccountName = $storageAccountNameLong.Substring( 0, [System.Math]::Min( 24, $storageAccountNameLong.Length ) ).ToLower();
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction Ignore;
if ( !$storageAccount )
{
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $resourceGroupLocation `
        -SkuName "Standard_LRS" -Kind "Storage" | Out-Null;
}

$configParameters.Machines | % {
    $machineName = $_.Name;
    $publicIpName = ( $machineName + "IP" );
    $pip = Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Name $publicIpName -ErrorAction Ignore;
    if ( !$pip )
    {
        $pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -AllocationMethod Dynamic -IdleTimeoutInMinutes 4 -Name $publicIpName -DomainNameLabel $machineName.ToLower();
    }

    $nsgName = ( $machineName + "-ngs")
    $nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName -ErrorAction Ignore;
    if ( !$nsg )
    {
        $nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name RDP -Protocol Tcp `
            -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
            -DestinationPortRange 3389 -Access Allow;
        $nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -Name $nsgName -SecurityRules $nsgRuleRDP;
        if ( $_.Roles -contains "WFE" )
        {
            $nsg | Add-AzureRmNetworkSecurityRuleConfig -Name Web -Protocol Tcp `
                -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
                -DestinationPortRange 80 -Access Allow | Out-Null;
            $nsg | Set-AzureRmNetworkSecurityGroup | Out-Null;
        }
    }

    $nicName = ( $machineName + "NIC" )
    $nic = Get-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName -Name $nicName -ErrorAction Ignore;
    if ( !$nic )
    {
        $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation `
            -SubnetId $subnetId -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
    }
        
    $vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $machineName -ErrorAction Ignore;
    if ( !$vm )
    {
        #Check machine sizes: Get-AzureRmVMSize -Location westeurope
        if ( $_.Memory -le 1.5 ) { $VMSize = "Basic_A1" } else { $VMSize = "Standard_D11_v2" }
        # Check SKUS: Get-AzureRmVMImageSku -Location westeurope -PublisherName MicrosoftWindowsServer -Offer WindowsServer
        if ( $_.DiskSize -le 30 ) { $skus = "2016-Datacenter-smalldisk" } else { $skus = "2016-Datacenter" }
        if ( $_.Roles -contains "AD" ) { $vmCredential = $DomainAdminCredential } else { $vmCredential = $LocalAdminCredential }
        $vmConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $VMSize | `
            Set-AzureRmVMOperatingSystem -Windows -ComputerName $machineName -Credential $vmCredential | `
            Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
            -Skus $skus -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
        New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -VM $vmConfig | Out-Null;
    }
}

$automationAccountName = ( $resourceGroupName + "Automation" );
$automationAccount = Get-AzureRmAutomationAccount -ResourceGroupName $resourceGroupName -Name $automationAccountName -ErrorAction Ignore;
if ( !$automationAccount )
{
    New-AzureRmAutomationAccount -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -Name $automationAccountName | Out-Null;
    $subscriptionId = (Get-AzureRmSubscription)[0].id;
    .\New-RunAsAccount.ps1 -ResourceGroup $resourceGroupName -AutomationAccountName $automationAccountName -SubscriptionId $subscriptionId -ApplicationDisplayName "$resourceGroupName Automation" -SelfSignedCertPlainPassword $azureParameters.AzureAutomationPassword -CreateClassicRunAsAccount $true
}

$configurationData = @{ AllNodes = [System.Collections.ArrayList]@() }
$configurationData.AllNodes.Add( @{ NodeName = "teet"; PSDscAllowPlainTextPassword = $True } )
$configurationDataString = "@{ AllNodes = @( ";
$strings = $configParameters.Machines | ? { $_.Roles -contains "AD" } | % {
    '@{ NodeName = "' + $_.Name + '"; PSDscAllowPlainTextPassword = $True }';
}

$configurationDataString += $strings -join ", "; 
$configurationDataString += ") }";
$tempConfigDataFilePath = $env:TEMP + "\tempconfigdata.psd1"
$configurationDataString | Set-Content -Path $tempConfigDataFilePath
$configFileName = "DSCSPDomainDevEnv.ps1";
Publish-AzureRmVMDscConfiguration $configFileName -ConfigurationDataPath $tempConfigDataFilePath -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force;
Remove-Item $tempConfigDataFilePath;

$configurationArguments = @{ configParameters=$configParameters }

$configParameters.Machines | ? { $_.Roles -contains "AD" } | % {
    Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $_.Name -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName "SPDomainDevEnv" -Verbose -Force -ConfigurationArgument $configurationArguments;
}
<#
#Use an existing Azure Virtual Machine, 'DscDemo1'
$demoVM = Get-AzureVM DscDemo1

#Publish the configuration script into user storage.
Publish-AzureVMDscConfiguration -ConfigurationPath ".\IisInstall.ps1" -StorageContext $storageContext -Verbose -Force

#Set the VM to run the DSC configuration
Set-AzureVMDscExtension -VM $demoVM -ConfigurationArchive "IisInstall.ps1.zip" -StorageContext $storageContext -ConfigurationName "IisInstall" -Verbose

#Update the configuration of an Azure Virtual Machine
$demoVM | Update-AzureVM -Verbose

#check on status
Get-AzureVMDscExtensionStatus -VM $demovm -Verbose

$azureCompilationParameters = @{
    ConfigParameters = $configParameters
}

$configParameters.Machines | % {
    Start-AzureRmAutomationDscCompilationJob -ResourceGroupName "development" -AutomationAccountName "lab2-automation" -ConfigurationName "SharePointDevelopmentEnvironment" -ConfigurationData configurationdata.psd1 -Parameters $azureCompilationParameters
}
#>