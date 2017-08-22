Configuration SP2013LoadingInstallationFiles
{
    param(
        $SPImageUrl,
        $SPServicePackURL,
        $SPCumulativeUpdateURL
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile
    Import-DscResource -ModuleName xStorage

    Node $AllNodes.NodeName
    {
        $SPImageUrl -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
        $SPImageFileName = $matches[0]
        $SPImageDestinationPath = "C:\Install\SPImage\$SPImageFileName"
        xRemoteFile SPServerImageFile
        {
            Uri             = $SPImageUrl
            DestinationPath = $SPImageDestinationPath
        }

        xMountImage SPServerImageMount
        {
            ImagePath   = $SPImageDestinationPath
            DriveLetter = 'S'
            DependsOn   = @("[xRemoteFile]SPServerImageFile")
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
            DestinationPath = "C:\Install\SPExtracted"
            DependsOn       = "[xWaitForVolume]WaitForSPServerImageMount"
        }

        if ( ( $SPServicePackURL ) -and ( $SPServicePackURL -ne "" ) )
        {
            $SPServicePackURL -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
            $SPServicePackFileName = $matches[0]
            xRemoteFile SPServicePackFile
            {
                Uri             = "$SPServicePackURL"
                DestinationPath = "C:\Install\SPExtracted\Updates\$SPServicePackFileName"
            }
        }

        if ( ( $SPCumulativeUpdateURL ) -and ( $SPCumulativeUpdateURL -ne "" ) )
        {
            $SPCumulativeUpdateURL -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
            $SPCumulativeUpdateFileName = $matches[0]
            xRemoteFile SPCumulativeUpdateFile
            {
                Uri             = "$SPCumulativeUpdateURL"
                DestinationPath = "C:\Install\SPExtracted\Updates\$SPCumulativeUpdateFileName"
            }
        }

    }
}
