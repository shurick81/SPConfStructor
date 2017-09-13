Configuration SPCodeTools
{
    param(
        $configParameters,
        $commonDictionary
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile

    Node $AllNodes.NodeName
    {

        xRemoteFile VSInstallerDownload
        {
            Uri             = $commonDictionary.VSVersions[ $configParameters.VSVersion ].Url
            DestinationPath = "C:\temp\vs_installer.exe"
        }

        Script VSInstallerRunning
        {
            SetScript = {
                Start-Process -FilePath C:\temp\vs_installer.exe -ArgumentList '--quiet --wait --add Microsoft.VisualStudio.Workload.Office' -Wait;
            }
            TestScript = {
                Get-WmiObject -Class Win32_Product | ? { $_.name -eq "Microsoft Visual Studio Setup Configuration" } | % { return $true }
                return $false
            }
            GetScript = {
                $installedApplications = Get-WmiObject -Class Win32_Product | ? { $_.name -eq "Microsoft Visual Studio Setup Configuration" }
                return $installedApplications
            }
            DependsOn = @( "[xRemoteFile]VSInstallerDownload" )
        }

    }
}