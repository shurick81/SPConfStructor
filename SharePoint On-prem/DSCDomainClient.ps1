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

    Node $AllNodes.NodeName
    {        

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }

        xDSCDomainJoin DomainJoin
        {
            Domain      = $configParameters.DomainName
            Credential  = $DomainAdminCredential
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

