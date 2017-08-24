Configuration SQL2014LoadingInstallationFiles
{
    param(
        $SQLImageUrl
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile
    Import-DscResource -ModuleName xStorage

    Node $AllNodes.NodeName
    {

        $SQLImageUrl -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
        $SQLImageFileName = $matches[0]
        $SQLImageDestinationPath = "C:\Install\SQLImage\$SQLImageFileName"
        xRemoteFile SQLServerImageFile
        {
            Uri = $SQLImageUrl
            DestinationPath = $SQLImageDestinationPath
        }

        xMountImage SQLServerImageMount
        {
            ImagePath   = $SQLImageDestinationPath
            DriveLetter = 'S'
            DependsOn   = "[xRemoteFile]SQLServerImageFile"
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
            DestinationPath = "C:\Install\SQLExtracted"
            DependsOn       = "[xWaitForVolume]WaitForSQLServerImageMount"
        }        
    }
}

