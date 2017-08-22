
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
$commonDictionary = Import-PowershellDataFile commonDictionary.psd1;

Write-Progress -Activity 'Deploying SharePoint farm in Azure' -PercentComplete (0) -id 0 -CurrentOperation "Resource group promotion";

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

$resourceGroupName = $azureParameters.ResourceGroupName;
$resourceGroupLocation = $azureParameters.ResourceGroupLocation;
$storageAccountNameLong = ( $resourceGroupName + "StdStor" );
$storageAccountName = $storageAccountNameLong.Substring( 0, [System.Math]::Min( 24, $storageAccountNameLong.Length ) ).ToLower();

#Login-AzureRmAccount


$resourceGroup = Get-AzureRmResourceGroup $resourceGroupName -ErrorAction Ignore;
if ( !$resourceGroup )
{
    $resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;
}

$vnetName = ( $resourceGroupName + "VNet");
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName -ErrorAction Ignore;
if ( !$vnet )
{
    $SubnetIpAddress = $azureParameters.SubnetIpAddress;
    $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name ( $resourceGroupName + "Subnet" ) -AddressPrefix "$SubnetIpAddress/24";
    $vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -Name $vnetName -AddressPrefix "$SubnetIpAddress/16" -Subnet $subnetConfig;
}
$subnetId = $vnet.Subnets[0].Id;

$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction Ignore;
if ( !$storageAccount )
{
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $resourceGroupLocation `
        -SkuName "Standard_LRS" -Kind "Storage" | Out-Null;
}

$automationAccountName = ( $resourceGroupName + "Automation" );
$automationAccount = Get-AzureRmAutomationAccount -ResourceGroupName $resourceGroupName -Name $automationAccountName -ErrorAction Ignore;
if ( !$automationAccount )
{
    New-AzureRmAutomationAccount -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -Name $automationAccountName | Out-Null;

    #Does not seem like this is needed
    $subscriptionId = (Get-AzureRmSubscription)[0].id;
    .\New-RunAsAccount.ps1 -ResourceGroup $resourceGroupName -AutomationAccountName $automationAccountName -SubscriptionId $subscriptionId -ApplicationDisplayName "$resourceGroupName Automation" -SelfSignedCertPlainPassword $azureParameters.AzureAutomationPassword -CreateClassicRunAsAccount $true
}

Write-Progress -Activity 'Deploying SharePoint farm in Azure' -PercentComplete (1) -id 1;

$configParameters.Machines | % {
    $machineName = $_.Name;
    Write-Progress -Activity 'Machines creation' -PercentComplete (0) -ParentId 1 -CurrentOperation $machineName;
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
        $skusPrefix = "2016"
        if ( $_.WinVersion -eq "2012" ) { $skusPrefix = "2012" }
        if ( $_.WinVersion -eq "2012R2" ) { $skusPrefix = "2012-R2" }
        if ( $_.DiskSize -le 30 ) { $skus = "$skusPrefix-Datacenter-smalldisk" } else { $skus = "$skusPrefix-Datacenter" }
        if ( $_.Roles -contains "AD" ) { $vmCredential = $DomainAdminCredential } else { $vmCredential = $LocalAdminCredential }
        $vmConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $VMSize | `
            Set-AzureRmVMOperatingSystem -Windows -ComputerName $machineName -Credential $vmCredential | `
            Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
            -Skus $skus -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
        New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -VM $vmConfig | Out-Null; 
        if ( $_.WinVersion -eq "2012" ) {
            #http://setspn.blogspot.ru/2015/06/working-with-powershell-dsc-and-azure.html
            $containerName = "psscripts";
            $fileName = "Win2012Prepare.ps1"
            $subscriptionName = (Get-AzureRmSubscription)[0].Name;
            Set-AzureRmCurrentStorageAccount -StorageAccountName $storageAccountName -ResourceGroupName $resourceGroupName;
            New-AzureStorageContainer -Name $containerName -Permission Off;
            Set-AzureStorageBlobContent -Container $containerName -File $fileName -Force;
            Set-AzureRmVMCustomScriptExtension -VM $machineName -ContainerName $containerName -FileName $fileName -Name $fileName -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -StorageAccountName $storageAccountName
        }
    }
}


$SPVersion = $configParameters.SPVersion;
if ( $SPVersion -eq "2013" ) { $SQLVersion = "2014" } else { $SQLVersion = "2016" }

# machines preparation

    Write-Progress -Activity 'Domain controller preparation' -PercentComplete (5)
    $ADMachines = $configParameters.Machines | ? { $_.Roles -contains "AD" }
    $ADMachines | % {
        $configName = "DomainPrepare"
        $configFileName = "DSC$configName.ps1";
        Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force;
        Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $_.Name -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force;
    }


    Write-Progress -Activity 'Deploying SharePoint farm in Azure' -PercentComplete (20) -id 1;
    $SQLMachines = $configParameters.Machines | ? { $_.Roles -contains "SQL" }
    $SQLMachines | % {
        $machineName = $_.Name;    
        if ( $_.ProvisioninngType -eq "URL" )
        {
            $configurationDataString = '@{ AllNodes = @( @{ NodeName = "' + $_.Name + '"; PSDscAllowPlainTextPassword = $True } ) }';
            $tempConfigDataFilePath = $env:TEMP + "\tempconfigdata.psd1"
            $configurationDataString | Set-Content -Path $tempConfigDataFilePath      

            $configName = "SQL$($SQLVersion)LoadingInstallationFiles";
            $configFileName = "DSC$configName.ps1";
            Publish-AzureRmVMDscConfiguration $configFileName -ConfigurationDataPath $tempConfigDataFilePath -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force;
            $sqlImageUrl = $commonDictionary.SQLVersions[$SQLVersion].RTMImageUrl;
            $configurationArguments = @{
                SQLImageUrl = $sqlImageUrl
            }
            Write-Progress -Activity 'SQL server installation files downloading' -PercentComplete (0) -CurrentOperation $machineName -ParentId 1;
            Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $machineName -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;
    
            $configName = "SQL$($SQLVersion)Prepare";
            $configFileName = "DSC$configName.ps1";
            Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force;
            $configurationArguments = @{ configParameters=$configParameters }
            Write-Progress -Activity 'SQL server preparation' -PercentComplete (0) -CurrentOperation $machineName -ParentId 1;
            Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $machineName -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;
        }
    }


    Write-Progress -Activity 'Deploying SharePoint farm in Azure' -PercentComplete (20) -id 1;
    $SPMachines = $configParameters.Machines | ? { $_.Roles -contains "SharePoint" }
    $SPMachines | % {
        $machineName = $_.Name;        
        if ( $_.ProvisioninngType -eq "URL" )
        {
            $configName = "SP$($SPVersion)LoadingInstallationFiles";
            $configFileName = "DSC$configName.ps1";
            Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force;
            $spImageUrl = $commonDictionary.SPVersions[$SPVersion].RTMImageUrl;
            $spServicePackUrl = $null;
            $SPServicePack = $configParameters.SPServicePack;
            if ( $SPServicePack -and ( $SPServicePack -ne "" ) )
            {
                $spServicePackUrl = $commonDictionary.SPVersions[$SPVersion].ServicePacks[$SPServicePack].Url;
            }
            $spCumulativeUpdateUrl = $null;
            $SPCumulativeUpdate = $configParameters.SPCumulativeUpdate;
            if ( $SPCumulativeUpdate -and ( $SPCumulativeUpdate -ne "" ) )
            {
                $spCumulativeUpdateUrl = $commonDictionary.SPVersions[$SPVersion].ServicePacks[$SPCumulativeUpdate].Url;
            }
            $configurationArguments = @{
                SPImageUrl = $spImageUrl
                SPServicePackUrl = $spServicePackUrl
                SPCumulativeUpdateUrl = $spCumulativeUpdateUrl
            }
            Write-Progress -Activity 'SharePoint server installation files downloading' -PercentComplete (0) -CurrentOperation $machineName -ParentId 1;
            Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $machineName -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;

            $configName = "SP$($SPVersion)Prepare";
            $configFileName = "DSC$configName.ps1";
            Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force;
            $configurationArguments = @{ configParameters=$configParameters }
            Write-Progress -Activity 'SharePoint server preparation' -PercentComplete (0) -CurrentOperation $machineName -ParentId 1;
            Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $machineName -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;
        }
    }

#machines are prepared

#Domain deploying
$ADMachines = $configParameters.Machines | ? { $_.Roles -contains "AD" }
if ( $ADMachines )
{
    $configName = "SPDomain"
    $configFileName = "DSC$configName.ps1";
    Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force;
    $configurationArguments = @{ configParameters=$configParameters }
    Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $_.Name -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;
}

#Joining machines to domain
$domainClientMachines = $configParameters.Machines | ? { !( $_.Roles -contains "AD" ) }
$domainClientMachines | % {
    $configName = "DomainClient"
    $configFileName = "DSC$configName.ps1";
    Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force;
    $configurationArguments = @{
        "ConfigParameters" = $configParameters
        "SystemParameters" = $azureParameters
    }
    Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $_.Name -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;
}


<#
$SPMachines = $configParameters.Machines | ? { $_.Roles -contains "SharePoint" }
$SPConfigurationMachines = $SPMachines | ? { $_.Roles -contains "Configuration" }
if ( !$configurationMachines )
{
    if ( $SPMachines )
    {
        $SPConfigurationMachines = @( $SPMachines[0] )
    }
}
$SPConfigurationMachines | % {
    $configurationDataString = "@{ AllNodes = @( ";
    $strings = $SPMachines | % {
        '@{ NodeName = "' + $_.Name + '"; PSDscAllowPlainTextPassword = $True }';
    }
    $configurationDataString += $strings -join ", "; 
    $configurationDataString += ") }";

    $configName = "SP$($SPVersion)";
    $configFileName = "DSC$configName.ps1";
    if ( $configParameters.SPVersion -eq "2013" ) { $configFileName = "DSCSP2013.ps1" } else { $configFileName = "DSCSP2016.ps1" }
    Publish-AzureRmVMDscConfiguration $configFileName -ConfigurationDataPath $tempConfigDataFilePath -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force;
    Remove-Item $tempConfigDataFilePath;
    $configurationArguments = @{ configParameters=$configParameters }
    Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $_.Name -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName "SPDomain" -Verbose -Force -ConfigurationArgument $configurationArguments;
}
#>

Get-Date
