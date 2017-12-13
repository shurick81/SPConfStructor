@( "AdminModules" ) | % {
    $parameterFile = $_;
    $moduleConfig = Import-PowershellDataFile "$parameterFile.psd1";
    $moduleConfig.Keys | % {
        $newestModule = Find-Module -Name $_
        if ( $newestModule.Version.ToString() -ne $moduleConfig.$_ )
        {
            Write-Host "In $parameterFile, $_ version in parameters is '$($moduleConfig.$_)' while the newest version is '$($newestModule.Version.ToString())'"
        }
    }
}
