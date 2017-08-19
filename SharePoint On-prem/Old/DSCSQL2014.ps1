Configuration SQL2014
{
    param(
        $configParameters
    )
    $DomainName = $configParameters.DomainName;
    $domainAdminUserName = $configParameters.DomainAdminUserName;
    $SPInstallAccountUserName = $configParameters.SPInstallAccountUserName;
    $SQLPass = $configParameters.SQLPass;

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

        if ( !$SPInstallAccountCredential )
        {
            if ( $SPInstallAccountUserName )
            {
                $securedPassword = ConvertTo-SecureString $configParameters.SPInstallAccountPassword -AsPlainText -Force
                $SPInstallAccountCredential = New-Object System.Management.Automation.PSCredential( "$shortDomainName\$SPInstallAccountUserName", $securedPassword )
            } else {
                $SPInstallAccountCredential = Get-Credential -Message "Credential for SharePoint install account";
            }
        }

        if ( !$SQLPassCredential )
        {
            if ( $SQLPass )
            {
                $securedPassword = ConvertTo-SecureString $SQLPass -AsPlainText -Force
                $SQLPassCredential = New-Object System.Management.Automation.PSCredential( "anyidentity", $securedPassword )
            } else {
                $SQLPassCredential = Get-Credential -Message "Enter any user name and enter SQL SA password";
            }
        }

    # credentials are ready

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile
    Import-DSCResource -ModuleName xDSCDomainJoin
    Import-DSCResource -ModuleName xNetworking
    
    $SQLMachineNames = $configParameters.Machines | ? { $_.Roles -contains "SQL" } | % { $_.Name }

    Node $SQLMachineNames
    {        
        if ( $configParameters.DomainControllerIP )
        {
            xDNSServerAddress DNSClient
            {
                Address         = $configParameters.DomainControllerIP
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

