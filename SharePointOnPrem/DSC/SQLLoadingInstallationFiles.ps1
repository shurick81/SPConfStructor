Configuration SQLLoadingInstallationFiles
{
    param(
        $configParameters,
        $systemParameters,
        $commonDictionary,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $MediaShareCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile -ModuleVersion 8.0.0.0
    Import-DscResource -ModuleName xStorage -ModuleVersion 3.3.0.0
    
    $SQLImageLocation = $systemParameters.SQLImageLocation
    $SPVersion = $configParameters.SPVersion;
    if ( $SPVersion -eq "2013" ) { $SQLVersion = "2014" } else { $SQLVersion = "2016" }
    $sqlImageUrl = $commonDictionary.SQLVersions[ $SQLVersion ].RTMImageUrl;

    Node $AllNodes.NodeName
    {

        if ( $systemParameters.SQLMediaSource -eq "Public" )
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
        if ( ( $systemParameters.SQLMediaSource -eq "Public" ) -and ( $systemParameters.SQLImageUnpack ) )
        {

            $sqlImageUrl -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
            $SQLImageFileName = $matches[0]
            $SQLImagePath = "$SQLImageLocation\$SQLImageFileName"

            if ( $systemParameters.SQLMediaSource -eq "Public" )
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
        if ( $systemParameters.SQLMediaSource -eq "PreparedShare" )
        {

            File Test {
                SourcePath = $systemParameters.SQLPreparedShare
                DestinationPath = $configParameters.SQLInstallationMediaPath
                Recurse = $true
                Type = "Directory"
                Credential = $MediaShareCredential
            }

        }
    }
}

