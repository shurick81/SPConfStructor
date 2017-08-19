#compiling mof files on your development machine
$configParameters = Import-PowershellDataFile mainParemeters.psd1;

#compiling domain
$configParameters.Machines | ? { $_.Roles -contains "AD" } | % {
    $configurationData = @{ AllNodes = @(
        @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    ) }
    . .\DSCSPDomain.ps1
    SPDomain -ConfigurationData $configurationData -ConfigParameters $configParameters
}

#compiling SQL
$configParameters.Machines | ? { $_.Roles -contains "SQL" } | % {
    $configurationData = @{ AllNodes = @(
        @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    ) }
    if ( $configParameters.SPVersion -eq "2013" )
    {
        . .\DSCSQL2014Prepare.ps1
        SQL2014Prepare -ConfigurationData $configurationData -ConfigParameters $configParameters
        . .\DSCSQL2014.ps1
        SQL2014 -ConfigurationData $configurationData -ConfigParameters $configParameters
    }
    if ( $configParameters.SPVersion -eq "2016" )
    {
        . .\DSCSQL2016.ps1
        SQL2016 -ConfigurationData $configurationData -ConfigParameters $configParameters
    }
}

#compiling SP
$configParameters.Machines | ? { $_.Roles -contains "SharePoint" } | % {
    $configurationData = @{ AllNodes = @(
        @{ NodeName = $_.Name; PSDscAllowPlainTextPassword = $True }
    ) }
    if ( $configParameters.SPVersion -eq "2013" )
    {
        . .\DSCSP2013Prepare.ps1
        SP2013Prepare -ConfigurationData $configurationData -ConfigParameters $configParameters
        . .\DSCSP2013.ps1
        SP2013 -ConfigurationData $configurationData -ConfigParameters $configParameters
        . .\DSCSPSearch.ps1
        SPSearch -ConfigurationData $configurationData -ConfigParameters $configParameters
    }
    if ( $configParameters.SPVersion -eq "2016" )
    {
        . .\DSCSQL2016.ps1
        SQL2016 -ConfigurationData $configurationData -ConfigParameters $configParameters
    }
}
