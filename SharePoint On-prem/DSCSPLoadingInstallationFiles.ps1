Configuration SPLoadingInstallationFiles
{
    param(
        $configParameters,
        $systemParameters,
        $commonDictionary,
        $azureStorageAccountKey
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile
    Import-DscResource -ModuleName cAzureStorage
    Import-DscResource -ModuleName xStorage

    $SPImageLocation = $systemParameters.SPImageLocation
    $SPInstallationMediaPath = $configParameters.SPInstallationMediaPath
    $SPVersion = $configParameters.SPVersion;

    Node $AllNodes.NodeName
    {

        $mountDependsOn = $null;
        if ( $systemParameters.SPImageSource -eq "Public" )
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
        if ( $systemParameters.SPImageSource -eq "AzureBlob" )
        {

            cAzureStorage SPServerImageFile {
                Path                    = $systemParameters.SPImageLocation
                StorageAccountName      = $systemParameters.ImageStorageAccount
                StorageAccountContainer = $systemParameters.SPImageAzureContainerName
                StorageAccountKey       = $azureStorageAccountKey
            }

            $mountDependsOn = @( "[cAzureStorage]SPServerImageFile" )
            
        }
        if ( $systemParameters.SPImageUnpack )
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

            <#
            File SPServerInstallatorDirectory
            {
                Ensure          = "Present"
                Type            = "Directory"
                Recurse         = $true
                SourcePath      = "P:\"
                DestinationPath = $SPInstallationMediaPath
                DependsOn       = "[xWaitForVolume]WaitForSPServerImageMount"
            }

            $SPCumulativeUpdateParameter = $configParameters.SPCumulativeUpdate
            if ( $SPCumulativeUpdateParameter -and ( $$SPCumulativeUpdateParameter -ne "") )
            {
                $temporaryFilesFolderPath = "C:\temp\SPCU\$SPVersion\$SPCumulativeUpdateParameter"
                $filesCounter = 0
                $commonDictionary.SPVersions[ $SPVersion ].CumulativeUpdates[ $SPCumulativeUpdateParameter ].Urls | % {
                    $_ -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
                    $SPCUFileName = $matches[0]
                    $SPCUFilePath = "$temporaryFilesFolderPath\$SPCUFileName"
                    xRemoteFile "SPCumulativeUpdateDownloading$filesCounter"
                    {
                        Uri             = $_
                        DestinationPath = $SPCUFilePath
                    }

                    $SPCUFileName -match '\.[^.]+$' | Out-Null
                    if ( $match[0] -eq ".exe" )
                    {

                        Script "CumulativeUpdateIncorporating$filesCounter"
                        {
                            SetScript = ( {
                                 {0} /extract: {1}\Updates\
                            } -f @( $SPCUFilePath, $SPInstallationMediaPath ) )
                            TestScript = ( {
                                Get-ChildItem {0}\Updates | ? { $_.Name -ne "readme.txt" } | % { return $true }
                                return $false
                            } -f @( $SPInstallationMediaPath ) )
                            GetScript = ( {
                                $extractedFiles = Get-ChildItem {0}\Updates | ? { $_.Name -ne "readme.txt" }
                                return @{ Result = "$extractedFiles" }
                            }
                        }

                    }
    
                    $filesCounter++;
                }
            }
            #>

            <#
            xRemoteFile AutoSPSourceBuilderPs1
            {
                Uri             = "https://raw.githubusercontent.com/brianlala/AutoSPSourceBuilder/master/AutoSPSourceBuilder.ps1"
                DestinationPath = "C:\temp\AutoSPSourceBuilder\AutoSPSourceBuilder.ps1"
            }
            #>

            cAzureStorage AutoSPSourceBuilderPs1File {
                Path                    = "C:\temp\AutoSPSourceBuilder"
                StorageAccountName      = $systemParameters.ImageStorageAccount
                StorageAccountContainer = "psscripts"
                StorageAccountKey       = $azureStorageAccountKey
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
    }
}
