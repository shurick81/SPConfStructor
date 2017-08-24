Configuration DomainClient
{
    param(
        $configParameters,
        $systemParameters
    )
    $DomainName = $configParameters.DomainName;
    $shortDomainName = $DomainName.Substring( 0, $DomainName.IndexOf( "." ) );

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xDSCDomainJoin
    Import-DSCResource -ModuleName xNetworking
    

    Node $DomainClientMachines
    {        
        if ( $systemParameters.DomainControllerIP )
        {

            xDNSServerAddress DNSClient
            {
                Address         = $systemParameters.DomainControllerIP
                AddressFamily   = "IPv4"
                InterfaceAlias  = "Ethernet 3"
            }

            xDSCDomainJoin DomainJoin
            {
                Domain      = $configParameters.DomainName
                Credential  = $configParameters.DomainAdminCredential
                DependsOn   = @("[xDNSServerAddress]DNSClient")
            }

        } else {       
            xDSCDomainJoin DomainJoin
            {
                Domain      = $configParameters.DomainName
                Credential  = $configParameters.DomainAdminCredential
            }
        }
        #Local group
        Group AdminGroup
        {
            GroupName           = "Administrators"
            Credential          = $configParameters.DomainAdminCredential
            MembersToInclude    = "$shortDomainName\$($configParameters.SPAdminGroupName)"
            DependsOn           = "[xDSCDomainJoin]DomainJoin"
        }
                
    }
}

