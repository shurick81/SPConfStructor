Configuration SPCodeToolsUser
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
    Import-DscResource -ModuleName cChoco -ModuleVersion 2.3.1.0
    
    Node $AllNodes.NodeName
    {

        cChocoInstaller installChoco        
        {
            InstallDir = "c:\choco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installnodejs
        {
            Name                    = "nodejs"
            DependsOn               = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installnotepadplusplus
        {
            Name                    = "notepadplusplus"
            DependsOn               = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installsharepointmanager
        {
            Name                    = "sharepointmanager2013"
            DependsOn               = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        } 
         
        cChocoPackageInstaller installcamldesigner
        {
            Name                    = "camldesigner2013"
            DependsOn               = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installsearchquerytool 
        {
            Name                    = "searchquerytool"
            DependsOn               = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installfiddler
        {
            Name                    = "fiddler4"
            DependsOn               = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installpostman
        {
            Name                    = "postman"
            DependsOn               = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

        Script installgulp
        {
            SetScript = {
                if ( !($env:Path -like "*C:\Program Files\nodejs\*") )
                {
                    $env:Path += ";C:\Program Files\nodejs\"
                }
                Start-Process -FilePath npm -ArgumentList 'install --global gulp' -Wait;
            }
            TestScript = {
                if ( !($env:Path -like "*C:\Program Files\nodejs\*") )
                {
                    $env:Path += ";C:\Program Files\nodejs\"
                }
                $result = npm list -g gulp
                if ( $result[1] -contains "gulp" ) { return $true } else { return $false }
            }
            GetScript = {
                if ( !($env:Path -like "*C:\Program Files\nodejs\*") )
                {
                    $env:Path += ";C:\Program Files\nodejs\"
                }
                $result = npm list -g gulp
                return @{ Result = $result[1] };
            }
            DependsOn = @( "[cChocoPackageInstaller]installnodejs" )
            PsDscRunAsCredential    = $UserCredential
        }

        <# to be developed
        xRemoteFile PowerShellVSIXDownload
        {
            Uri             = "https://github.com/PowerShell/vscode-powershell/releases/download/v1.5.0/PowerShell-1.5.0.vsix"
            DestinationPath = "C:\temp\PowerShell-1.5.0.vsix"
        }

        Script PowerShellVSIXInstallation
        {
            SetScript = ( {
                if ( !($env:Path -like "*C:\Program Files\Microsoft VS Code\*") )
                {
                    $env:Path += ";C:\Program Files\Microsoft VS Code\"
                }
                Start-Process -FilePath 'C:\Program Files\Microsoft VS Code\code.exe' -ArgumentList ' --install-extension C:\temp\PowerShell-1.5.0.vsix' -Wait;
            } -f @( $configParameters.VSVersion ) )
            TestScript = ( {
                $folder = $null;
                $folder = Get-ChildItem "C:\Program Files (x86)\Microsoft Visual Studio\2017\{0}\Common7\IDE\Extensions\navris5c.nu3" -ErrorAction SilentlyContinue;
                if ( $folder ) { return $true } else { return $false }
            } -f @( $configParameters.VSVersion ) )
            GetScript = ( {
                $folder = $null;
                $folder = Get-ChildItem "C:\Program Files (x86)\Microsoft Visual Studio\2017\{0}\Common7\IDE\Extensions\navris5c.nu3" -ErrorAction SilentlyContinue;
                if ( $folder ) { return @{ Result = "Folder exists" } } else { return @{ Result = "Folder does not exist" } }
            } -f @( $configParameters.VSVersion ) )
            DependsOn = @( "[Script]VSInstallerRun", "[xRemoteFile]SPFxVSIXDownload" )
        }
        #>

        Registry LocalZone
        {
            Ensure                  = "Present"
            Key                     = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\$SPSiteCollectionHostName"
            ValueName               = "http"
            ValueType               = "DWord"
            ValueData               = "1"
            PsDscRunAsCredential    = $SPInstallAccountCredential
        }

    }
}