Configuration SPLoadingInstallationFiles
{
    param(
        $configParameters,
        $systemParameters,
        $commonDictionary,
        $imageAzureStorageAccountKey,
        $scriptAzureStorageAccountKey,
        $scriptAccountName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $MediaShareCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile -ModuleVersion 8.0.0.0
    Import-DscResource -ModuleName cAzureStorage
    Import-DscResource -ModuleName xStorage

    $SPImageLocation = $systemParameters.SPImageLocation
    $SPInstallationMediaPath = $configParameters.SPInstallationMediaPath
    $SPVersion = $configParameters.SPVersion;

    Node $AllNodes.NodeName
    {

        $mountDependsOn = $null;
        if ( $systemParameters.SPMediaSource -eq "Public" )
        {
            $spImageUrl = $commonDictionary.SPVersions[ $SPVersion ].RTMImageUrl;
            $SPImageUrl -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
            $SPImageFileName = $matches[0]
            $SPImageDestinationPath = "$SPImageLocation\$SPImageFileName"

            xRemoteFile SPServerImageFile
            {
                Uri             = $SPImageUrl
                DestinationPath = $SPImageDestinationPath
            }

            $mountDependsOn = @( "[xRemoteFile]SPServerImageFile" )
        } else {
            $SPImageFileName = $systemParameters.SPImageFileName            
        }
        if ( $systemParameters.SPMediaSource -eq "AzureBlobImage" )
        {

            cAzureStorage SPServerImageFile {
                Path                    = $systemParameters.SPImageLocation
                StorageAccountName      = $systemParameters.ImageStorageAccount
                StorageAccountContainer = $systemParameters.SPImageAzureContainerName
                StorageAccountKey       = $imageAzureStorageAccountKey
            }

            $mountDependsOn = @( "[cAzureStorage]SPServerImageFile" )
            
        }
        if ( ( ( $systemParameters.SPMediaSource -eq "Public" ) -or ( $systemParameters.SPMediaSource -eq "AzureBlobImage" ) ) -and $systemParameters.SPImageUnpack )
        {
            $SPImagePath = "$SPImageLocation\$SPImageFileName"

            if ( $mountDependsOn )
            {

                xMountImage SPServerImageMount
                {
                    ImagePath   = $SPImagePath
                    DriveLetter = 'P'
                    DependsOn   = $mountDependsOn
                }

            } else {
                
                xMountImage SPServerImageMount
                {
                    ImagePath   = $SPImagePath
                    DriveLetter = 'P'
                }
                
            }

            xWaitForVolume WaitForSPServerImageMount
            {
                DriveLetter         = 'P'
                RetryIntervalSec    = 5
                RetryCount          = 10
                DependsOn           = "[xMountImage]SPServerImageMount"
            }

            cAzureStorage AutoSPSourceBuilderPs1File {
                Path                    = "C:\temp\AutoSPSourceBuilder"
                StorageAccountName      = $scriptAccountName
                StorageAccountContainer = "psscripts"
                StorageAccountKey       = $scriptAzureStorageAccountKey
            }

            xRemoteFile AutoSPSourceBuilderXml
            {
                Uri             = "https://raw.githubusercontent.com/brianlala/AutoSPSourceBuilder/master/AutoSPSourceBuilder.xml"
                DestinationPath = "C:\temp\AutoSPSourceBuilder\AutoSPSourceBuilder.xml"
            }
            
            $resultString = '@{ Result = "$extractedFiles" }'
            Script AutoSPSourceBuilderRunning
            {
                SetScript = ( {
                    C:\temp\AutoSPSourceBuilder\AutoSPSourceBuilder.ps1 -SourceLocation "P:" -Destination "{0}" -CumulativeUpdate "{1}" -Languages "{2}"
                } -f @( $SPInstallationMediaPath, $configParameters.SPCumulativeUpdate, $configParameters.SPLanguagePacks ) )
                TestScript = ( {
                    Get-ChildItem {0}\{1}\SharePoint\Updates -ErrorAction SilentlyContinue | ? {{ $_.Name -ne "readme.txt" }} | % {{ return $true }}
                    return $false
                } -f @( $SPInstallationMediaPath, $SPVersion ) )
                GetScript = ( {
                    $extractedFiles = Get-ChildItem {0}\{1}\SharePoint\Updates -ErrorAction SilentlyContinue | ? {{ $_.Name -ne "readme.txt" }}
                    return {2}
                } -f @( $SPInstallationMediaPath, $SPVersion, $resultString ) )
                DependsOn = @( "[xWaitForVolume]WaitForSPServerImageMount", "[cAzureStorage]AutoSPSourceBuilderPs1File", "[xRemoteFile]AutoSPSourceBuilderXml" )
            }
    
        }
        if ( $systemParameters.SPMediaSource -eq "PreparedShare" )
        {

            File Test {
                SourcePath = $systemParameters.SPPreparedShare
                DestinationPath = $configParameters.SPInstallationMediaPath
                Recurse = $true
                Type = "Directory"
                Credential = $MediaShareCredential
            }

        }
    }
}
