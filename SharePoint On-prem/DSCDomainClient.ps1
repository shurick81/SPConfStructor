Configuration DomainClient
{
    param(
        $configParameters,
        $systemParameters,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $DomainAdminCredential
    )
    $DomainName = $configParameters.DomainName;
    $shortDomainName = $DomainName.Substring( 0, $DomainName.IndexOf( "." ) );

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xDSCDomainJoin
    Import-DSCResource -ModuleName xNetworking
    <#
    Import-DscResource -ModuleName xCredSSP
    #>
    
    <#
    $domainClientMachines = $configParameters.Machines | ? { !( $_.Roles -contains "AD" ) } | % { $_.Name }
    #>

    Node $AllNodes.NodeName
    {        

        $machineParameters = $configParameters.Machines | ? { $_.Name -eq $NodeName }

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }

        if ( $false )
        {
            $interfaceAlias = "Ethernet"
            $winVersion = $machineParameters.WinVersion;
            $imageParameter = $machineParameters.Image;
            if ( ( ( $winVersion -eq "2016" ) -or ( $winVersion -eq "2012" ) ) -and ( !$imageParameter -or ( $imageParameter -eq "" ) ) )
            {
                $interfaceAlias = "Ethernet 3"
            }

            xDNSServerAddress DNSClient
            {
                AddressFamily   = "IPv4"
                InterfaceAlias  = $interfaceAlias
                Address         = $systemParameters.DomainControllerIP
            }

            xDSCDomainJoin DomainJoin
            {
                Domain      = $configParameters.DomainName
                Credential  = $DomainAdminCredential
                DependsOn   = @("[xDNSServerAddress]DNSClient")
            }

        } else {

            xDSCDomainJoin DomainJoin
            {
                Domain      = $configParameters.DomainName
                Credential  = $DomainAdminCredential
            }

        }

        #Local group
        Group AdminGroup
        {
            GroupName           = "Administrators"
            Credential          = $DomainAdminCredential
            MembersToInclude    = "$shortDomainName\$($configParameters.SPAdminGroupName)"
            DependsOn           = "[xDSCDomainJoin]DomainJoin"
        }

        if ( $machineParameters.Roles -contains "SQL" )
        {
            Group DBAdminGroup
            {
                GroupName           = "DBAdmins"
                Credential          = $DomainAdminCredential
                MembersToInclude    = "$shortDomainName\$($configParameters.SPAdminGroupName)"
                DependsOn           = "[xDSCDomainJoin]DomainJoin"
            }
        }

    }
}

