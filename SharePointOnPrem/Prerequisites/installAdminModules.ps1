#WMF 5.0 or later is needed: https://docs.microsoft.com/en-us/powershell/wmf/5.1/install-configure


#you need this for compiling mofs on your development machine
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
@( "AdminModules" ) | % {
    $moduleConfig = Import-PowershellDataFile "$_.psd1";
    $moduleConfig.Keys | % {
        $version = $moduleConfig.$_
        if ( $version -ne "" )
        {
            Install-Module -Name $_ -Force -RequiredVersion $version
        } else {
            Install-Module -Name $_ -Force
        }
    }
}