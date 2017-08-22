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

        <#
        $SQLImageUrlParts = $SQLImageUrl.Split("/");
        $SQLImageFileName = $SQLImageUrlParts[$SQLImageUrlParts.Count - 1];
        $SQLImageDestinationPath = "C:\Install\SQLImage\$SQLImageFileName"
        #>

        $SQLImageUrl -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
        $SQLImageFileName = $matches[0]
        $SQLImageDestinationPath = "C:\Install\SPImage\$SQLImageFileName"

        xRemoteFile SQLServerImageFile
        {
            Uri = $SQLImageUrl
            DestinationPath = $SQLImageDestinationPath
        }

        <#
        xRemoteFile SQLServerImageFile
        {
            Uri = "http://care.dlservice.microsoft.com/dl/download/2/F/8/2F8F7165-BB21-4D1E-B5D8-3BD3CE73C77D/SQLServer2014SP1-FullSlipstream-x64-ENU.iso"
            DestinationPath = "C:\Install\SQLImage\SQLServer2014SP1-FullSlipstream-x64-ENU.iso"
        }
        #>

        xMountImage SQLServerImageMount
        {
            ImagePath   = "C:\Install\SQLImage\SQLServer2014SP1-FullSlipstream-x64-ENU.iso"
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

