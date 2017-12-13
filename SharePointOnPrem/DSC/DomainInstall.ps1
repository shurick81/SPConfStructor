Configuration DomainInstall
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xRemoteDesktopAdmin -ModuleVersion 1.1.0.0
    Import-DscResource -ModuleName xActiveDirectory -ModuleVersion 2.16.0.0
    
    Node $AllNodes.NodeName
    {

        <#
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
        #>

        #For domain controller only?
        xRemoteDesktopAdmin DCRDPSettings
        {
           Ensure               = 'Present'
           UserAuthentication   = 'NonSecure'
        }

        WindowsFeatureSet DomainFeatures
        {
            Name                    = @( "DNS", "RSAT-DNS-Server", "AD-Domain-Services", "RSAT-ADDS" )
            Ensure                  = 'Present'
            IncludeAllSubFeature    = $true
        } 
                
    }
}