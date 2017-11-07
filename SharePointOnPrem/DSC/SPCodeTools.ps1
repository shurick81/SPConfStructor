Configuration SPCodeTools
{
    param(
        $configParameters,
        $commonDictionary,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $UserCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile
    Import-DSCResource -Module xSystemSecurity -Name xIEEsc
    Import-DscResource -ModuleName cChoco

    Node $AllNodes.NodeName
    {

        Registry LoopBackRegistry
        {
            Ensure      = "Present"
            Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName   = "DisableLoopbackCheck"
            ValueType   = "DWORD"
            ValueData   = "1"
        }

        xIEEsc DisableIEEsc
        {
            IsEnabled   = $false
            UserRole    = "Administrators"
        }

        xRemoteFile VSInstallerDownload
        {
            Uri             = $commonDictionary.VSVersions[ $configParameters.VSVersion ].Url
            DestinationPath = "C:\temp\vs_installer.exe"
        }

        Script VSInstallerRun
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
                return @{ Result = $installedApplications }
            }
            DependsOn = @( "[xRemoteFile]VSInstallerDownload" )
        }

        xRemoteFile SPFxVSIXDownload
        {
            Uri             = "https://github.com/SharePoint/sp-dev-fx-vs-extension/releases/download/v1.3.3/Framework.VSIX.vsix"
            DestinationPath = "C:\temp\Framework.VSIX.vsix"
        }

        $resultObj = '@{ Result = "$resultString" }'        
        Script SPFxVSIXInstallation
        {
            SetScript = ( {
                Start-Process -FilePath 'C:\Program Files (x86)\Microsoft Visual Studio\2017\{0}\Common7\IDE\VSIXInstaller.exe' -ArgumentList '/a /q "C:\temp\Framework.VSIX.vsix"' -Wait;
            } -f @( $configParameters.VSVersion ) )
            TestScript = ( {
                $folder = $null;
                $folder = Get-ChildItem "C:\Program Files (x86)\Microsoft Visual Studio\2017\{0}\Common7\IDE\Extensions\navris5c.nu3" -ErrorAction SilentlyContinue;
                if ( $folder ) {{ return $true }} else {{ return $false }}
            } -f @( $configParameters.VSVersion ) )
            GetScript = ( {
                $folder = $null;
                $folder = Get-ChildItem "C:\Program Files (x86)\Microsoft Visual Studio\2017\{0}\Common7\IDE\Extensions\navris5c.nu3" -ErrorAction SilentlyContinue;
                if ( $folder ) {{ $resultString = "Folder exists" }} else {{ $resultString = "Folder does not exist" }}
                return {1}
            } -f @( $configParameters.VSVersion, $resultObj ) )
            DependsOn = @( "[Script]VSInstallerRun", "[xRemoteFile]SPFxVSIXDownload" )
        }

        cChocoInstaller installChoco
        {
            InstallDir = "c:\choco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installsharepointdesigner
        {
            Name                    = "sharepointdesigner2013x32"
            DependsOn               = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installvisualstudiocode
        {
            Name                    = "visualstudiocode"
            DependsOn               = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installnodejs
        {
            Name                    = "nodejs"
            DependsOn               = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installgit
        {
            Name                    = "git"
            DependsOn               = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

    }
}