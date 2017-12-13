#following resources are to be installed on the SQL Node
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

@( "SQLModules" ) | % {
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