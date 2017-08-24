
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

# examining, generating and requesting credentials

    $domainAdminUserName = $configParameters.DomainAdminUserName;
    if ( $domainAdminUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.DomainAdminPassword -AsPlainText -Force
        $domainAdminCredential = New-Object System.Management.Automation.PSCredential( "$domainAdminUserName", $securedPassword )
    } else {
        $domainAdminCredential = Get-Credential -Message "Credential with domain administrator privileges";
    }
    $configParameters.DomainAdminCredential = $domainAdminCredential;

    $DomainSafeModeAdministratorPassword = $configParameters.DomainSafeModeAdministratorPassword;
    if ( $DomainSafeModeAdministratorPassword )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.DomainSafeModeAdministratorPassword -AsPlainText -Force
        $DomainSafeModeAdministratorPasswordCredential = New-Object System.Management.Automation.PSCredential( "anyidentity", $securedPassword )
    } else {
        $DomainSafeModeAdministratorPasswordCredential = Get-Credential -Message "Enter any but not empty login and safe mode password";
    }
    $configParameters.DomainSafeModeAdministratorPasswordCredential = $DomainSafeModeAdministratorPasswordCredential;

    $localAdminUserName = $azureParameters.LocalAdminUserName;
    if ( $localAdminUserName )
    {
        $securedPassword = ConvertTo-SecureString $azureParameters.LocalAdminPassword -AsPlainText -Force
        $localAdminCredential = New-Object System.Management.Automation.PSCredential( "$localAdminUserName", $securedPassword )
    } else {
        $localAdminCredential = Get-Credential -Message "Credential with local administrator privileges";
    }
    $configParameters.LocalAdminCredential = $localAdminCredential;

    $SPInstallAccountUserName = $configParameters.SPInstallAccountUserName;
    if ( $SPInstallAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPInstallAccountPassword -AsPlainText -Force
        $SPInstallAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPInstallAccountUserName", $securedPassword )
    } else {
        $SPInstallAccountCredential = Get-Credential -Message "Credential for SharePoint install account";
    }
    $configParameters.SPInstallAccountCredential = $SPInstallAccountCredential;

    $SPFarmAccountUserName = $configParameters.SPFarmAccountUserName;
    if ( $SPFarmAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPFarmAccountPassword -AsPlainText -Force
        $SPFarmAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPFarmAccountUserName", $securedPassword )
    } else {
        $SPFarmAccountCredential = Get-Credential -Message "Credential for SharePoint farm account";
    }
    $configParameters.SPFarmAccountCredential = $SPFarmAccountCredential;

    $SPWebAppPoolAccountUserName = $configParameters.SPWebAppPoolAccountUserName;
    if ( $SPWebAppPoolAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPWebAppPoolAccountPassword -AsPlainText -Force
        $SPWebAppPoolAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPWebAppPoolAccountUserName", $securedPassword )
    } else {
        $SPWebAppPoolAccountCredential = Get-Credential -Message "Credential for SharePoint Web Application app pool account";
    }
    $configParameters.SPWebAppPoolAccountCredential = $SPWebAppPoolAccountCredential;

    $SPServicesAccountUserName = $configParameters.SPServicesAccountUserName;
    if ( $SPServicesAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPServicesAccountPassword -AsPlainText -Force
        $SPServicesAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPServicesAccountUserName", $securedPassword )
    } else {
        $SPServicesAccountCredential = Get-Credential -Message "Credential for SharePoint shared services app pool";
    }
    $configParameters.SPServicesAccountCredential = $SPServicesAccountCredential;

    $SPSearchServiceAccountUserName = $configParameters.SPSearchServiceAccountUserName;
    if ( $SPSearchServiceAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPSearchServiceAccountPassword -AsPlainText -Force
        $SPSearchServiceAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPSearchServiceAccountUserName", $securedPassword )
    } else {
        $SPSearchServiceAccountCredential = Get-Credential -Message "Credential for SharePoint search service account";
    }
    $configParameters.SPSearchServiceAccountCredential = $SPSearchServiceAccountCredential;

    $SPCrawlerAccountUserName = $configParameters.SPCrawlerAccountUserName;
    if ( $SPCrawlerAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPCrawlerAccountPassword -AsPlainText -Force;
        $SPCrawlerAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPCrawlerAccountUserName", $securedPassword );
    } else {
        $SPCrawlerAccountCredential = Get-Credential -Message "Credential for SharePoint crawler account";
    }
    $configParameters.SPCrawlerAccountCredential = $SPCrawlerAccountCredential;

    $SPTestAccountUserName = $configParameters.SPTestAccountUserName;
    if ( $SPTestAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPTestAccountPassword -AsPlainText -Force;
        $SPTestAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPTestAccountUserName", $securedPassword );
    } else {
        $SPTestAccountCredential = Get-Credential -Message "Credential for SharePoint test user";
    }
    $configParameters.SPTestAccountCredential = $SPTestAccountCredential;

    $SPSecondTestAccountUserName = $configParameters.SPSecondTestAccountUserName;
    if ( $SPSecondTestAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPSecondTestAccountPassword -AsPlainText -Force
        $SPSecondTestAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPSecondTestAccountUserName", $securedPassword );
    } else {
        $SPSecondTestAccountCredential = Get-Credential -Message "Credential for SharePoint test user";
    }
    $configParameters.SPSecondTestAccountCredential = $SPSecondTestAccountCredential;

    $SPOCAccountPass = ConvertTo-SecureString "Any3ligiblePa`$`$" -AsPlainText -Force;
    $SPOCAccountCredential = New-Object System.Management.Automation.PSCredential( "anyusername", $SPOCAccountPass );
    $configParameters.SPOCAccountCredential = $SPOCAccountCredential

    $SQLPass = $configParameters.SQLPass;
    if ( $SQLPass )
    {
        $securedPassword = ConvertTo-SecureString $SQLPass -AsPlainText -Force
        $SQLPassCredential = New-Object System.Management.Automation.PSCredential( "anyidentity", $securedPassword )
    } else {
        $SQLPassCredential = Get-Credential -Message "Enter any user name and enter SQL SA password";
    }
    $configParameters.SQLPassCredential = $SQLPassCredential;

    $SPPassPhrase = $configParameters.SPPassPhrase;
    if ( $SPPassPhrase )
    {
        $securedPassword = ConvertTo-SecureString $SPPassPhrase -AsPlainText -Force
        $SPPassphraseCredential = New-Object System.Management.Automation.PSCredential( "anyidentity", $securedPassword )
    } else {
        $SPPassphraseCredential = Get-Credential -Message "Enter any user name and enter pass phrase in password field";
    }
    $configParameters.SPPassphraseCredential = $SPPassphraseCredential;

# credentials are ready

$resourceGroupName = $azureParameters.ResourceGroupName;
$resourceGroupLocation = $azureParameters.ResourceGroupLocation;
$storageAccountNameLong = ( $resourceGroupName + "StdStor" );
$storageAccountName = $storageAccountNameLong.Substring( 0, [System.Math]::Min( 24, $storageAccountNameLong.Length ) ).ToLower();
$vnetName = ( $resourceGroupName + "VNet");

if ( $azureParameters.Login )
{
    Login-AzureRmAccount
}

if ( $azureParameters.DeleteResourceGroup )
{
    .\azurePurge.ps1
}

Write-Progress -Activity 'Deploying SharePoint farm in Azure' -PercentComplete (0) -id 0 -CurrentOperation "Resource group promotion";
if ( $azureParameters.PrepareResourceGroup )
{
    $resourceGroup = Get-AzureRmResourceGroup $resourceGroupName -ErrorAction Ignore;
    if ( !$resourceGroup )
    {
        $resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;
    }

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
        <#
        $subscriptionId = (Get-AzureRmSubscription)[0].id;
        .\New-RunAsAccount.ps1 -ResourceGroup $resourceGroupName -AutomationAccountName $automationAccountName -SubscriptionId $subscriptionId -ApplicationDisplayName "$resourceGroupName Automation" -SelfSignedCertPlainPassword $azureParameters.AzureAutomationPassword -CreateClassicRunAsAccount $true
        #>
    }
}

Write-Progress -Activity 'Deploying SharePoint farm in Azure' -PercentComplete (1) -id 1;

if ( $azureParameters.CreateVMs )
{
    $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName;
    $subnetId = $vnet.Subnets[0].Id;

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
                $containerName = "psscripts";
                $fileName = "Win2012Prepare.ps1"
                $subscriptionName = (Get-AzureRmSubscription)[0].Name;
                Set-AzureRmCurrentStorageAccount -StorageAccountName $storageAccountName -ResourceGroupName $resourceGroupName;
                $existingStorageContainer = $null;
                $existingStorageContainer = Get-AzureStorageContainer $containerName -ErrorAction SilentlyContinue;
                if ( !$existingStorageContainer )
                {
                    New-AzureStorageContainer -Name $containerName -Permission Off | Out-Null;
                }
                Set-AzureStorageBlobContent -Container $containerName -File $fileName -Force | Out-Null;
                Set-AzureRmVMCustomScriptExtension -VM $machineName -ContainerName $containerName -FileName $fileName -Name $fileName -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -StorageAccountName $storageAccountName
            }
        }
    }
}


$SPVersion = $configParameters.SPVersion;
if ( $SPVersion -eq "2013" ) { $SQLVersion = "2014" } else { $SQLVersion = "2016" }

# machines preparation

    Write-Progress -Activity 'Domain controller preparation' -PercentComplete (5)
    if ( $azureParameters.ADInstall )
    {
        $ADMachines = $configParameters.Machines | ? { $_.Roles -contains "AD" }
        $ADMachines | % {
            $configName = "DomainInstall"
            $configFileName = "DSC$configName.ps1";
            Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force | Out-Null;
            Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $_.Name -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force;
        }
    }


    Write-Progress -Activity 'Deploying SharePoint farm in Azure' -PercentComplete (20) -id 1;
    $SQLMachines = $configParameters.Machines | ? { $_.Roles -contains "SQL" }
    $SQLMachines | % {
        $machineName = $_.Name;    
        if ( $azureParameters.DownloadInstallationFiles -and ( $azureParameters.SQLImageSource -eq "Public" ) )
        {
            $configName = "SQL$($SQLVersion)LoadingInstallationFiles";
            $configFileName = "DSC$configName.ps1";
            Publish-AzureRmVMDscConfiguration $configFileName <#-ConfigurationDataPath $tempConfigDataFilePath #>-ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force | Out-Null;
            $sqlImageUrl = $commonDictionary.SQLVersions[$SQLVersion].RTMImageUrl;
            $configurationArguments = @{
                SQLImageUrl = $sqlImageUrl
            }
            Write-Progress -Activity 'SQL server installation files downloading' -PercentComplete (0) -CurrentOperation $machineName -ParentId 1;
            Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $machineName -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;
        }

        if ( $azureParameters.SQLInstall )
        {
            $configName = "SQL$($SQLVersion)Install";
            $configFileName = "DSC$configName.ps1";
            Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force | Out-Null;
            $configurationArguments = @{
                configParameters = $configParameters
                SQLPassCredential = $configParameters.SQLPassCredential
            }
            Write-Progress -Activity 'SQL server preparation' -PercentComplete (0) -CurrentOperation $machineName -ParentId 1;
            Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $machineName -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;
        }
    }


    Write-Progress -Activity 'Deploying SharePoint farm in Azure' -PercentComplete (20) -id 1;
    $SPMachines = $configParameters.Machines | ? { $_.Roles -contains "SharePoint" }
    $SPMachines | % {
        $machineName = $_.Name;        
        if ( $azureParameters.DownloadInstallationFiles )
        {
            if ( $azureParameters.SPImageSource -eq "Public" )
            {
                $configName = "SP$($SPVersion)LoadingInstallationFiles";
                $configFileName = "DSC$configName.ps1";
                Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force | Out-Null;
                $spImageUrl = $commonDictionary.SPVersions[$SPVersion].RTMImageUrl;
                $spServicePackUrl = "";
                $SPServicePack = $configParameters.SPServicePack;
                if ( $SPServicePack -and ( $SPServicePack -ne "" ) )
                {
                    $spServicePackUrl = $commonDictionary.SPVersions[$SPVersion].ServicePacks[$SPServicePack].Url;
                }
                $spCumulativeUpdateUrl = "";
                $SPCumulativeUpdate = $configParameters.SPCumulativeUpdate;
                if ( $SPCumulativeUpdate -and ( $SPCumulativeUpdate -ne "" ) )
                {
                    $spCumulativeUpdateUrl = $commonDictionary.SPVersions[$SPVersion].CumulativeUpdates[$SPCumulativeUpdate].Url;
                }
                $configurationArguments = @{
                    SPImageUrl = $spImageUrl
                    SPServicePackUrl = $spServicePackUrl
                    SPCumulativeUpdateUrl = $spCumulativeUpdateUrl
                }
                Write-Progress -Activity 'SharePoint server installation files downloading' -PercentComplete (0) -CurrentOperation $machineName -ParentId 1;
                Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $machineName -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;
            }
            if ( $azureParameters.SPImageSource -eq "AzureBlob" )
            {
                $configName = "SP$($SPVersion)LoadingInstallationFiles";
                $configFileName = "DSC$configName.ps1";
                Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force | Out-Null;
                $spImageUrl = $commonDictionary.SPVersions[$SPVersion].RTMImageUrl;
                $spServicePackUrl = "";
                $SPServicePack = $configParameters.SPServicePack;
                if ( $SPServicePack -and ( $SPServicePack -ne "" ) )
                {
                    $spServicePackUrl = $commonDictionary.SPVersions[$SPVersion].ServicePacks[$SPServicePack].Url;
                }
                $spCumulativeUpdateUrl = "";
                $SPCumulativeUpdate = $configParameters.SPCumulativeUpdate;
                if ( $SPCumulativeUpdate -and ( $SPCumulativeUpdate -ne "" ) )
                {
                    $spCumulativeUpdateUrl = $commonDictionary.SPVersions[$SPVersion].CumulativeUpdates[$SPCumulativeUpdate].Url;
                }
                $configurationArguments = @{
                    SPImageUrl = $spImageUrl
                    SPServicePackUrl = $spServicePackUrl
                    SPCumulativeUpdateUrl = $spCumulativeUpdateUrl
                }
                Write-Progress -Activity 'SharePoint server installation files downloading' -PercentComplete (0) -CurrentOperation $machineName -ParentId 1;
                Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $machineName -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;
            }
        }

        if ( $azureParameters.SPInstall )
        {
            $configName = "SP$($SPVersion)Install";
            $configFileName = "DSC$configName.ps1";
            Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force | Out-Null;
            $configurationArguments = @{
                ConfigParameters = $configParameters
                #Needed?
                LocalAdminCredential = $LocalAdminCredential
            }
            Write-Progress -Activity 'SharePoint server preparation' -PercentComplete (0) -CurrentOperation $machineName -ParentId 1;
            Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $machineName -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;
        }
    }

#machines are prepared

#Domain deploying
if ( $azureParameters.InstallDomain )
{
    $ADMachines = $configParameters.Machines | ? { $_.Roles -contains "AD" }
    $ADMachines | % {
        $configName = "SPDomain"
        $configFileName = "DSC$configName.ps1";
        Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force | Out-Null;
        $configurationArguments = @{
            configParameters = $configParameters
            DomainAdminCredential = $DomainAdminCredential
            DomainSafeModeAdministratorPasswordCredential = $DomainSafeModeAdministratorPasswordCredential
            SPInstallAccountCredential = $SPInstallAccountCredential
            SPFarmAccountCredential = $SPFarmAccountCredential
            SPWebAppPoolAccountCredential = $SPWebAppPoolAccountCredential
            SPServicesAccountCredential = $SPServicesAccountCredential
            SPSearchServiceAccountCredential = $SPSearchServiceAccountCredential
            SPCrawlerAccountCredential = $SPCrawlerAccountCredential
            SPOCAccountCredential = $SPOCAccountCredential
            SPTestAccountCredential = $SPTestAccountCredential
            SPSecondTestAccountCredential = $SPSecondTestAccountCredential
        }
        Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $_.Name -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;
    }
}

#Joining machines to domain
if ( $azureParameters.JoinDomain )
{
    $domainClientMachines = $configParameters.Machines | ? { !( $_.Roles -contains "AD" ) }
    $domainClientMachines | % {
        $configName = "DomainClient"
        $configFileName = "DSC$configName.ps1";
        Publish-AzureRmVMDscConfiguration $configFileName -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force | Out-Null;
        $configurationArguments = @{
            "ConfigParameters" = $configParameters
            "SystemParameters" = $azureParameters
        }
        Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $_.Name -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName $configName -Verbose -Force -ConfigurationArgument $configurationArguments;
    }
}


if ( $azureParameters.ConfigureSharePoint )
{
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
        $tempConfigDataFilePath = $env:TEMP + "\tempconfigdata.psd1"
        $configurationDataString | Set-Content -Path $tempConfigDataFilePath

        $configName = "SP$($SPVersion)";
        $configFileName = "DSC$configName.ps1";
        if ( $configParameters.SPVersion -eq "2013" ) { $configFileName = "DSCSP2013.ps1" } else { $configFileName = "DSCSP2016.ps1" }
        Publish-AzureRmVMDscConfiguration $configFileName -ConfigurationDataPath $tempConfigDataFilePath -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -Verbose -Force | Out-Null;
        Remove-Item $tempConfigDataFilePath;
        $configurationArguments = @{ ConfigParameters = $configParameters }
        Set-AzureRmVmDscExtension -Version 2.21 -ResourceGroupName $resourceGroupName -VMName $_.Name -ArchiveStorageAccountName $storageAccountName -ArchiveBlobName "$configFileName.zip" -AutoUpdate:$true -ConfigurationName "SPDomain" -Verbose -Force -ConfigurationArgument $configurationArguments;
    }
}

Get-Date
