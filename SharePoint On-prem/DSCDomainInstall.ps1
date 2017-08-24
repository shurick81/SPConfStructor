Configuration DomainInstall
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xRemoteDesktopAdmin
    Import-DscResource -ModuleName xActiveDirectory
    
    Node $AllNodes.NodeName
    {

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }

        #For domain controller only?
        xRemoteDesktopAdmin DCRDPSettings
        {
           Ensure               = 'Present'
           UserAuthentication   = 'NonSecure'
        }

        WindowsFeatureSet DomainFeatures
        {
            Name                    = @("DNS", "AD-Domain-Services", "RSAT-ADDS")
            Ensure                  = 'Present'
            IncludeAllSubFeature    = $true
        } 
                
    }
}