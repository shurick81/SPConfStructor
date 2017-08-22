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

$SPVersion = $configParameters.SPVersion;
if ( $SPVersion -eq "2013" ) { $SQLVersion = "2014" } else { $SQLVersion = "2016" }

#compiling domain
$configParameters.Machines | ? { $_.Roles -contains "AD" } | % {
    $configurationData = @{ AllNodes = @(
        @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    ) }
    . .\DSCDomainPrepare.ps1
    DomainPrepare -ConfigurationData $configurationData
    . .\DSCSPDomain.ps1
    SPDomain -ConfigurationData $configurationData -ConfigParameters $configParameters
}

#compiling SQL
$configParameters.Machines | ? { $_.Roles -contains "SQL" } | % {
    if ( $_.ProvisioninngType -eq "URL" )
    {
        $configurationData = @{ AllNodes = @(
            @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
        ) }
        if ( $configParameters.SPVersion -eq "2013" )
        {
            $sqlImageUrl = $commonDictionary.SQLVersions[$SQLVersion].RTMImageUrl;
            . .\DSCSQL2014LoadingInstallationFiles.ps1
            SQL2014LoadingInstallationFiles -ConfigurationData $configurationData -SQLImageUrl $sqlImageUrl
            . .\DSCSQL2014Prepare.ps1
            SQL2014Prepare -ConfigurationData $configurationData -ConfigParameters $configParameters
        }
        if ( $configParameters.SPVersion -eq "2016" )
        {
            . .\DSCSQL2016.ps1
            SQL2016 -ConfigurationData $configurationData -ConfigParameters $configParameters
        }
    }
}

#compiling SP machine preparation config
$configParameters.Machines | ? { $_.Roles -contains "SharePoint" } | % {
    $configurationData = @{ AllNodes = @(
        @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    ) }
    if ( $configParameters.SPVersion -eq "2013" )
    {
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
        . .\DSCSP2013LoadingInstallationFiles.ps1
        SP2013LoadingInstallationFiles -ConfigurationData $configurationData -SPImageUrl $spImageUrl -SPServicePackUrl $spServicePackUrl -SPCumulativeUpdate $spCumulativeUpdateUrl
        . .\DSCSP2013Prepare.ps1
        SP2013Prepare -ConfigurationData $configurationData -ConfigParameters $configParameters -SystemParameters $azureParameters
    }
    if ( $configParameters.SPVersion -eq "2016" )
    {
        . .\DSCSQL2016.ps1
        SQL2016 -ConfigurationData $configurationData -ConfigParameters $configParameters
    }
}

#compiling domain machine adding
$configParameters.Machines | ? { !( $_.Roles -contains "AD" ) } | % {
    $configurationData = @{ AllNodes = @(
        @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    ) }
    . .\DSCDomainClient.ps1
    DomainClient -ConfigurationData $configurationData -ConfigParameters $configParameters -SystemParameters $azureParameters
}

#compiling SPFarm configuration
$SPMachines = $configParameters.Machines | ? { $_.Roles -contains "SharePoint" }
if ( $SPMachines )
{
    $configurationData = @{ AllNodes = @() }
    $SPMachines | ? { $_.Roles -contains "SharePoint" } | % {
        $configurationData.AllNodes += @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    }
    . .\DSCSP2013.ps1
    SP2013 -ConfigurationData $configurationData -ConfigParameters $configParameters
}
