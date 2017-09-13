# script for compiling mof files on your development machine

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=1)]
    [string]$mainParametersFileName = "mainParemeters.psd1",
	
    [Parameter(Mandatory=$False,Position=2)]
    [string]$azureParametersFileName = "azureParameters.psd1"
)

$configParameters = Import-PowershellDataFile $mainParametersFileName;
$azureParameters = Import-PowershellDataFile $azureParametersFileName;
$commonDictionary = Import-PowershellDataFile commonDictionary.psd1;

$DomainName = $configParameters.DomainName;
$shortDomainName = $DomainName.Substring( 0, $DomainName.IndexOf( "." ) );

$SPVersion = $configParameters.SPVersion;
if ( $SPVersion -eq "2013" ) { $SQLVersion = "2014" } else { $SQLVersion = "2016" }

# examining, generating and requesting credentials

    $domainAdminUserName = $configParameters.DomainAdminUserName;
    if ( $domainAdminUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.DomainAdminPassword -AsPlainText -Force
        $shortDomainAdminCredential = New-Object System.Management.Automation.PSCredential( "$domainAdminUserName", $securedPassword )
    } else {
        $shortDomainAdminCredential = Get-Credential -Message "Credential with domain administrator privileges";
    }

    $domainAdminUserName = $configParameters.DomainAdminUserName;
    if ( $domainAdminUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.DomainAdminPassword -AsPlainText -Force
        $domainAdminCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$domainAdminUserName", $securedPassword )
    } else {
        $domainAdminCredential = Get-Credential -Message "Credential with domain administrator privileges";
    }

    $DomainSafeModeAdministratorPassword = $configParameters.DomainSafeModeAdministratorPassword;
    if ( $DomainSafeModeAdministratorPassword )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.DomainSafeModeAdministratorPassword -AsPlainText -Force
        $DomainSafeModeAdministratorPasswordCredential = New-Object System.Management.Automation.PSCredential( "anyidentity", $securedPassword )
    } else {
        $DomainSafeModeAdministratorPasswordCredential = Get-Credential -Message "Enter any but not empty login and safe mode password";
    }

    $localAdminUserName = $azureParameters.LocalAdminUserName;
    if ( $localAdminUserName )
    {
        $securedPassword = ConvertTo-SecureString $azureParameters.LocalAdminPassword -AsPlainText -Force
        $localAdminCredential = New-Object System.Management.Automation.PSCredential( "$localAdminUserName", $securedPassword )
    } else {
        $localAdminCredential = Get-Credential -Message "Credential with local administrator privileges";
    }

    $SPInstallAccountUserName = $configParameters.SPInstallAccountUserName;
    if ( $SPInstallAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPInstallAccountPassword -AsPlainText -Force
        $SPInstallAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPInstallAccountUserName", $securedPassword )
    } else {
        $SPInstallAccountCredential = Get-Credential -Message "Credential for SharePoint install account";
    }

    $SPFarmAccountUserName = $configParameters.SPFarmAccountUserName;
    if ( $SPFarmAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPFarmAccountPassword -AsPlainText -Force
        $SPFarmAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPFarmAccountUserName", $securedPassword )
    } else {
        $SPFarmAccountCredential = Get-Credential -Message "Credential for SharePoint farm account";
    }

    $SPWebAppPoolAccountUserName = $configParameters.SPWebAppPoolAccountUserName;
    if ( $SPWebAppPoolAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPWebAppPoolAccountPassword -AsPlainText -Force
        $SPWebAppPoolAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPWebAppPoolAccountUserName", $securedPassword )
    } else {
        $SPWebAppPoolAccountCredential = Get-Credential -Message "Credential for SharePoint Web Application app pool account";
    }

    $SPServicesAccountUserName = $configParameters.SPServicesAccountUserName;
    if ( $SPServicesAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPServicesAccountPassword -AsPlainText -Force
        $SPServicesAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPServicesAccountUserName", $securedPassword )
    } else {
        $SPServicesAccountCredential = Get-Credential -Message "Credential for SharePoint shared services app pool";
    }

    $SPSearchServiceAccountUserName = $configParameters.SPSearchServiceAccountUserName;
    if ( $SPSearchServiceAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPSearchServiceAccountPassword -AsPlainText -Force
        $SPSearchServiceAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPSearchServiceAccountUserName", $securedPassword )
    } else {
        $SPSearchServiceAccountCredential = Get-Credential -Message "Credential for SharePoint search service account";
    }

    $SPCrawlerAccountUserName = $configParameters.SPCrawlerAccountUserName;
    if ( $SPCrawlerAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPCrawlerAccountPassword -AsPlainText -Force;
        $SPCrawlerAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPCrawlerAccountUserName", $securedPassword );
    } else {
        $SPCrawlerAccountCredential = Get-Credential -Message "Credential for SharePoint crawler account";
    }

    $SPTestAccountUserName = $configParameters.SPTestAccountUserName;
    if ( $SPTestAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPTestAccountPassword -AsPlainText -Force;
        $SPTestAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPTestAccountUserName", $securedPassword );
    } else {
        $SPTestAccountCredential = Get-Credential -Message "Credential for SharePoint test user";
    }

    $SPSecondTestAccountUserName = $configParameters.SPSecondTestAccountUserName;
    if ( $SPSecondTestAccountUserName )
    {
        $securedPassword = ConvertTo-SecureString $configParameters.SPSecondTestAccountPassword -AsPlainText -Force
        $SPSecondTestAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPSecondTestAccountUserName", $securedPassword );
    } else {
        $SPSecondTestAccountCredential = Get-Credential -Message "Credential for SharePoint test user";
    }

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

    $MediaShareUserName = $azureParameters.MediaShareUserName;
    if ( $MediaShareUserName )
    {
        $securedPassword = ConvertTo-SecureString $azureParameters.MediaSharePassword -AsPlainText -Force
        $MediaShareCredential = New-Object System.Management.Automation.PSCredential( "$MediaShareUserName", $securedPassword );
    } else {
        $MediaShareCredential = Get-Credential -Message "Credential for media shared folder";
    }

# credentials are ready
$subscription = $null;
$subscription = Get-AzureRmSubscription;
if ( !$subscription )
{
    Write-Host "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    Write-Host "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
    Write-Host "||||||||||||||||||Don't worry about this error above||||||||||||||||||"
    Login-AzureRmAccount | Out-Null;
}

#compiling domain
$configParameters.Machines | ? { $_.Roles -contains "AD" } | % {
    $configurationData = @{ AllNodes = @(
        @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    ) }
    . .\DSC\DomainInstall.ps1
    DomainInstall -OutputPath .\dscoutput\DomainInstall -ConfigurationData $configurationData
    . .\DSC\SPDomain.ps1
    SPDomain -OutputPath .\dscoutput\SPDomain -ConfigurationData $configurationData -ConfigParameters $configParameters `
        -ShortDomainAdminCredential $ShortDomainAdminCredential `
        -DomainSafeModeAdministratorPasswordCredential $DomainSafeModeAdministratorPasswordCredential `
        -SPInstallAccountCredential $SPInstallAccountCredential `
        -SPFarmAccountCredential $SPFarmAccountCredential `
        -SPWebAppPoolAccountCredential $SPWebAppPoolAccountCredential `
        -SPServicesAccountCredential $SPServicesAccountCredential `
        -SPSearchServiceAccountCredential $SPSearchServiceAccountCredential `
        -SPCrawlerAccountCredential $SPCrawlerAccountCredential `
        -SPOCAccountCredential $SPOCAccountCredential `
        -SPTestAccountCredential $SPTestAccountCredential `
        -SPSecondTestAccountCredential $SPSecondTestAccountCredential `
        -MachineName $_.Name
}

#compiling SQL
$configParameters.Machines | ? { $_.Roles -contains "SQL" } | % {
    $configurationData = @{ AllNodes = @(
        @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    ) }
    . .\DSC\SQLLoadingInstallationFiles.ps1
    SQLLoadingInstallationFiles -OutputPath .\dscoutput\SQLLoadingInstallationFiles -ConfigurationData $configurationData -ConfigParameters $configParameters -SystemParameters $azureParameters -CommonDictionary $commonDictionary -MediaShareCredential $MediaShareCredential
    . .\DSC\SQLInstall.ps1
    SQLInstall -OutputPath .\dscoutput\SQLInstall -ConfigurationData $configurationData -ConfigParameters $configParameters -SQLPassCredential $configParameters.SQLPassCredential -LocalAdminCredential $LocalAdminCredential -MachineName $_.Name
}

#compiling SP machine preparation config
$configParameters.Machines | ? { $_.Roles -contains "SharePoint" } | % {
    $configurationData = @{ AllNodes = @(
        @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    ) }
    $storageAccountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $azureParameters.ImageResourceGroupName -Name $azureParameters.ImageStorageAccount | ? { $_.KeyName -eq "key1" }
    . .\DSC\SP2013Prepare.ps1
    SP2013Prepare -OutputPath .\dscoutput\SP2013Prepare -ConfigurationData $configurationData -ConfigParameters $configParameters
    . .\DSC\SPLoadingInstallationFiles.ps1
    SPLoadingInstallationFiles -OutputPath .\dscoutput\SPLoadingInstallationFiles -ConfigurationData $configurationData -ConfigParameters $configParameters -SystemParameters $azureParameters -CommonDictionary $commonDictionary -AzureStorageAccountKey $storageAccountKey.Value -MediaShareCredential $MediaShareCredential
    . .\DSC\SPInstall.ps1
    SPInstall -OutputPath .\dscoutput\SPInstall -ConfigurationData $configurationData -ConfigParameters $configParameters -CommonDictionary $commonDictionary;
}

#compiling configuration machines provisioning
$configParameters.Machines | ? { $_.Roles -contains "Configuration" } | % {
    $configurationData = @{ AllNodes = @(
        @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    ) }
    . .\DSC\SPConfigurationTools.ps1
    SPConfigurationTools -OutputPath .\dscoutput\SPConfigurationTools -ConfigurationData $configurationData -ConfigParameters $configParameters -CommonDictionary $commonDictionary
}

#compiling coding machines provisioning
$configParameters.Machines | ? { $_.Roles -contains "Code" } | % {
    $configurationData = @{ AllNodes = @(
        @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    ) }
    . .\DSC\SPCodeTools.ps1
    SPCodeTools -OutputPath .\dscoutput\SPCodeTools -ConfigurationData $configurationData -ConfigParameters $configParameters -CommonDictionary $commonDictionary
}

#compiling domain machine adding
$firstAdVMName = $null;
$configParameters.Machines | ? { $_.Roles -contains "AD" } | % {
    if ( !$firstAdVMName ) { $firstAdVMName = $_.Name }
}
$vm = Get-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -VMName $firstAdVMName;
$networkInterfaceRef = $vm.NetworkProfile[0].NetworkInterfaces[0].id;
$networkInterface = Get-AzureRmNetworkInterface | ? { $_.Id -eq $networkInterfaceRef }
$azureParameters.DomainControllerIP = $networkInterface.IpConfigurations[0].PrivateIpAddress 
$configParameters.Machines | ? { !( $_.Roles -contains "AD" ) } | % {
    $configurationData = @{ AllNodes = @(
        @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    ) }
    . .\DSC\DomainClient.ps1
    DomainClient -OutputPath .\dscoutput\DomainClient -ConfigurationData $configurationData -ConfigParameters $configParameters -SystemParameters $azureParameters -DomainAdminCredential $DomainAdminCredential
}

#compiling SPFarm configuration
$SPMachines = $configParameters.Machines | ? { $_.Roles -contains "SharePoint" }
if ( $SPMachines )
{
    $configurationData = @{ AllNodes = @() }
    $SPMachines | ? { $_.Roles -contains "SharePoint" } | % {
        $configurationData.AllNodes += @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    }
    . .\DSC\SPFarm.ps1
    SPFarm -OutputPath .\dscoutput\SPFarm -ConfigurationData $configurationData -ConfigParameters $configParameters `
        -SPPassphraseCredential $SPPassphraseCredential `
        -SPInstallAccountCredential $SPInstallAccountCredential `
        -SPFarmAccountCredential $SPFarmAccountCredential `
        -SPWebAppPoolAccountCredential $SPWebAppPoolAccountCredential `
        -SPServicesAccountCredential $SPServicesAccountCredential `
        -SPSearchServiceAccountCredential $SPSearchServiceAccountCredential `
        -SPCrawlerAccountCredential $SPCrawlerAccountCredential
}
