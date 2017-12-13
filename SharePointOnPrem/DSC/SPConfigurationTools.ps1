Configuration SPConfigurationTools
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
    Import-DSCResource -Module xSystemSecurity -Name xIEEsc -ModuleVersion 1.2.0.0
    Import-DsCResource -Module xWindowsUpdate -Name xHotfix -ModuleVersion 2.7.0.0
    Import-DscResource -ModuleName xPendingReboot -ModuleVersion 0.3.0.0
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile -ModuleVersion 8.0.0.0
    Import-DscResource -ModuleName cChoco -ModuleVersion 2.3.1.0
    
    $SSMSVersion = $configParameters.SSMSVersion;
    $SSMSUrl = $commonDictionary.SSMSVersions[$SSMSVersion].Url;
    $SSMSProductId = $commonDictionary.SSMSVersions[$SSMSVersion].ProductId;
    $SSMSUrl -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null;
    $SSMSInstallerFileName = $matches[0];
    $SSMSInstallerPath = "$($configParameters.SSMSInstallationFolderPath)\$SSMSInstallerFileName";

    Node $AllNodes.NodeName
    {
        #Only needed for manual mof installation, not for automated?
        <#
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
        #>
         
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

        xRemoteFile SQLMSInstallationFile
        {
            Uri             = $SSMSUrl
            DestinationPath = $SSMSInstallerPath
        }
        
        Package SSMS
        {
            Ensure      = "Present"
            Name        = "SMS-Setup-ENU"
            Path        = $SSMSInstallerPath
            Arguments   = "/install /passive /norestart"
            ProductId   = $SSMSProductId
            Credential  = $SPInstallAccountCredential
            DependsOn   = "[xRemoteFile]SQLMSInstallationFile"
        }
        
        WindowsFeatureSet DomainFeatures
        {
            Name                    = @( "RSAT-ADDS", "RSAT-DNS-Server" )
            Ensure                  = 'Present'
            IncludeAllSubFeature    = $true
        } 

        cChocoInstaller installChoco        
        {
            InstallDir              = "c:\choco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installulsviewer
        {
            Name                    = "ulsviewer"
            DependsOn               = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

    }
}
