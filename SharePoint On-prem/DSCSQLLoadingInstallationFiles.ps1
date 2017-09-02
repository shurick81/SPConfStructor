Configuration SQLLoadingInstallationFiles
{
    param(
        $configParameters,
        $systemParameters,
        $commonDictionary
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile
    Import-DscResource -ModuleName xStorage

    $SQLImageLocation = $systemParameters.SQLImageLocation
    $SPVersion = $configParameters.SPVersion;
    if ( $SPVersion -eq "2013" ) { $SQLVersion = "2014" } else { $SQLVersion = "2016" }
    $sqlImageUrl = $commonDictionary.SQLVersions[ $SQLVersion ].RTMImageUrl;

    Node $AllNodes.NodeName
    {

        if ( $systemParameters.SQLImageSource -eq "Public" )
        {

            $sqlImageUrl -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
            $SQLImageFileName = $matches[0]
            $SQLImageDestinationPath = "$SQLImageLocation\$SQLImageFileName"
            xRemoteFile SQLServerImageFile
            {
                Uri             = $SQLImageUrl
                DestinationPath = $SQLImageDestinationPath
            }
        }
        if ( $systemParameters.SQLImageUnpack )
        {

            $sqlImageUrl -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
            $SQLImageFileName = $matches[0]
            $SQLImagePath = "$SQLImageLocation\$SQLImageFileName"

            if ( $systemParameters.SQLImageSource -eq "Public" )
            {

                xMountImage SQLServerImageMount
                {
                    ImagePath   = $SQLImagePath
                    DriveLetter = 'S'
                    DependsOn   = "[xRemoteFile]SQLServerImageFile"
                }

            } else {

                xMountImage SQLServerImageMount
                {
                    ImagePath   = $SQLImagePath
                    DriveLetter = 'S'
                }

            }
            
            xWaitForVolume WaitForSQLServerImageMount
            {
                DriveLetter         = 'S'
                RetryIntervalSec    = 5
                RetryCount          = 10
                DependsOn           = "[xMountImage]SQLServerImageMount"
            }

            File SQLServerInstallatorDirectory
            {
                Ensure          = "Present"
                Type            = "Directory"
                Recurse         = $true
                SourcePath      = "S:\"
                DestinationPath = $configParameters.SQLInstallationMediaPath
                DependsOn       = "[xWaitForVolume]WaitForSQLServerImageMount"
            }
            
        }
    }
}

