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
    Import-DSCResource -ModuleName xDSCDomainJoin -ModuleVersion 1.1
    Import-DSCResource -ModuleName xNetworking -ModuleVersion 5.3.0.0

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

        $machineParameters = $configParameters.Machines | ? { $_.Name -eq $NodeName }

        #Local groups
        $localAdminsToInclude = @()
        if ( $machineParameters.Roles -contains "SQL" )
        {
            $localAdminsToInclude += "$shortDomainName\$($configParameters.SQLAdminGroupName)"
        }
        if ( ( $configParameters.Machines | ? { $_.Name -eq $NodeName } ).Roles -contains "SharePoint" )
        {
            $localAdminsToInclude += "$shortDomainName\$($configParameters.SPAdminGroupName)"
        }
        if ( $localAdminsToInclude.Count -gt 0 )
        {

            Group AdminGroup
            {
                GroupName           = "Administrators"
                Credential          = $DomainAdminCredential
                MembersToInclude    = $localAdminsToInclude
                DependsOn           = "[xDSCDomainJoin]DomainJoin"
            }

        }
    }
}

