Configuration SPConfigurationTools
{
    param(
        $configParameters,
        $commonDictionary
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -Module xSystemSecurity -Name xIEEsc
    Import-DsCResource -Module xWindowsUpdate -Name xHotfix
    Import-DscResource -ModuleName xPendingReboot
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile

    $SSMSVersion = $configParameters.SSMSVersion;
    $SSMSUrl = $commonDictionary.SSMSVersions[$SSMSVersion].Url;
    $SSMSProductId = $commonDictionary.SSMSVersions[$SSMSVersion].ProductId;
    $SSMSUrl -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null;
    $SSMSInstallerFileName = $matches[0];
    $SSMSInstallerPath = "$($configParameters.SSMSInstallationFolderPath)\$SSMSInstallerFileName";

    Node $AllNodes.NodeName
    {
        #Only needed for manual mof installation, not for automated?
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
         
        Registry LoopBackRegistry
        {
            Ensure      = "Present"  # You can also set Ensure to "Absent"
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
            Name                    = @( "RSAT-ADDS" )
            Ensure                  = 'Present'
            IncludeAllSubFeature    = $true
        } 

    }
}
