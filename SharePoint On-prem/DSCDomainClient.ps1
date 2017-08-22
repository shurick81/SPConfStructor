Configuration DomainClient
{
    param(
        $configParameters,
        $systemParameters
    )
    $DomainName = $configParameters.DomainName;
    $domainAdminUserName = $configParameters.DomainAdminUserName;

    $shortDomainName = $DomainName.Substring( 0, $DomainName.IndexOf( "." ) );

    # examining, generating and requesting credentials
    
        if ( !$DomainAdminCredential )
        {
            if ( $domainAdminUserName )
            {
                $securedPassword = ConvertTo-SecureString $configParameters.DomainAdminPassword -AsPlainText -Force
                $domainAdminCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$domainAdminUserName", $securedPassword )
            } else {
                $domainAdminCredential = Get-Credential -Message "Credential with domain administrator privileges";
            }
        }

    # credentials are ready

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
        }
                       
        xDSCDomainJoin DomainJoin
        {
            Domain      = $DomainName
            Credential  = $DomainAdminCredential
            DependsOn   = @("[xDNSServerAddress]DNSClient")
        }
        
        #Local group
        Group AdminGroup
        {
            GroupName           = "Administrators"
            Credential          = $DomainAdminCredential
            MembersToInclude    = "$shortDomainName\$($configParameters.SPAdminGroupName)"
            DependsOn           = "[xDSCDomainJoin]DomainJoin"
        }
                
    }
}

