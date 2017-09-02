Configuration SP2013LoadingInstallationFiles
{
    param(
        $configParameters,
        $systemParameters,
        $commonDictionary
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile
    Import-DscResource -ModuleName xStorage

    $SPImageLocation = $systemParameters.SPImageLocation
    $SPInstallationMediaPath = $configParameters.SPInstallationMediaPath
    $SPVersion = $configParameters.SPVersion;

    Node $AllNodes.NodeName
    {
        if ( $systemParameters.SPImageSource -eq "Public" )
        {
            $spImageUrl = $commonDictionary.SPVersions[$SPVersion].RTMImageUrl;
            $SPImageUrl -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
            $SPImageFileName = $matches[0]
            $SPImageDestinationPath = "$SPImageLocation\$SPImageFileName"

            xRemoteFile SPServerImageFile
            {
                Uri             = $SPImageUrl
                DestinationPath = $SPImageDestinationPath
            }
            
        }
        if ( $systemParameters.SPImageUnpack )
        {

            if ( $systemParameters.SPImageSource -eq "Public" )
            {
                $SPImagePath = "$SPImageLocation\$SPImageFileName"
                xMountImage SPServerImageMount
                {
                    ImagePath   = $SPImagePath
                    DriveLetter = 'S'
                    DependsOn   = @("[xRemoteFile]SPServerImageFile")
                }
            
            } else {
                $SPImageFileName = $systemParameters.SPImageFileName
                $SPImagePath = "$SPImageLocation\$SPImageFileName"
                xMountImage SPServerImageMount
                {
                    ImagePath   = $SPImagePath
                    DriveLetter = 'S'
                }

            }
            xWaitForVolume WaitForSPServerImageMount
            {
                DriveLetter         = 'S'
                RetryIntervalSec    = 5
                RetryCount          = 10
                DependsOn           = "[xMountImage]SPServerImageMount"
            }

            File SPServerInstallatorDirectory
            {
                Ensure          = "Present"
                Type            = "Directory"
                Recurse         = $true
                SourcePath      = "S:\"
                DestinationPath = $SPInstallationMediaPath
                DependsOn       = "[xWaitForVolume]WaitForSPServerImageMount"
            }

        }

        $SPServicePack = $configParameters.SPServicePack;
        if ( $SPServicePack -and ( $SPServicePack -ne "" ) )
        {
            if ( $systemParameters.SPServicePackSource -eq "Public" )
            {
                $spServicePackUrl = $commonDictionary.SPVersions[$SPVersion].ServicePacks[$SPServicePack].Url;
                $SPServicePackURL -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
                $SPServicePackFileName = $matches[0]

                xRemoteFile SPServicePackFile
                {
                    Uri             = "$SPServicePackURL"
                    DestinationPath = "$SPInstallationMediaPath\Updates\$SPServicePackFileName"
                }

            }
        }

        if ( $systemParameters.SPCumulativeUpdateSource -eq "Public" )
        {
            $SPCumulativeUpdate = $configParameters.SPCumulativeUpdate;
            if ( $SPCumulativeUpdate -and ( $SPCumulativeUpdate -ne "" ) )
            {
                $spCumulativeUpdateUrls = $commonDictionary.SPVersions[$SPVersion].CumulativeUpdates[$SPCumulativeUpdate].Urls;
                $SPCumulativeUpdateUrls | % {
                    $SPCumulativeUpdateUrl = $_
                    $SPCumulativeUpdateUrl -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
                    $SPCumulativeUpdateFileName = $matches[0]

                    xRemoteFile "SPCumulativeUpdateFile$counter"
                    {
                        Uri             = "$SPCumulativeUpdateURL"
                        DestinationPath = "$SPInstallationMediaPath\Updates\$SPCumulativeUpdateFileName"
                    }

                    $counter++;
                }
            }
        }

    }
}
