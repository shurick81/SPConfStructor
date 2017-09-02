Configuration SP2013Ent
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
    Import-DSCResource -ModuleName xDSCDomainJoin
    Import-DSCResource -ModuleName xNetworking
    Import-DSCResource -ModuleName xSQLServer -Name xSQLServerSetup

    Node $SP2016EntDevMachineName
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
        
        xDNSServerAddress DNSClient
        {
            Address         = $configParameters.DomainControllerIP
            AddressFamily   = "IPv4"
            InterfaceAlias  = "Ethernet 3"
        }
               
        xFireWall SQLFirewallRule
        {
            Name        = "AllowSQLConnection"
            DisplayName = "Allow SQL Connection"
            Group       = "DSC Rules"
            Ensure      = "Present"
            Enabled     = "True"
            Profile     = ("Domain")
            Direction   = "InBound"
            LocalPort   = ("1433")
            Protocol    = "TCP"
            Description = "Firewall rule to allow SQL communication"
        }
        
        xDSCDomainJoin DomainJoin
        {
            Domain      = $DomainName
            Credential  = $DomainAdminCredential
            DependsOn   = @("[xDNSServerAddress]DNSClient","[Registry]LoopBackRegistry")
        }
        
        #Local group
        Group AdminGroup
        {
            GroupName           = "Administrators"
            Credential          = $DomainAdminCredential
            MembersToInclude    = "$shortDomainName\$($configParameters.SPAdminGroupName)"
            DependsOn           = "[xDSCDomainJoin]DomainJoin"
        }
        
        xRemoteFile SQLServerImageFile
        {
            DestinationPath = "c:\install\SQLImage"
            Uri = "http://care.dlservice.microsoft.com/dl/download/F/E/9/FE9397FA-BFAB-4ADD-8B97-91234BC774B2/SQLServer2016-x64-ENU.iso"
        }

        xRemoteFile SQLMSInstallationFile
        {
            DestinationPath = "c:\install\SMS"
            Uri = "https://download.microsoft.com/download/C/3/D/C3DBFF11-C72E-429A-A861-4C316524368F/SSMS-Setup-ENU.exe"
        }

        xSQLServerSetup SQLSetup
        {
            InstanceName        = "MSSQLServer"
            SourcePath          = "C:\Install\SQL 2016"
            Features            = "SQLENGINE,FULLTEXT"
            InstallSharedDir    = "C:\Program Files\Microsoft SQL Server"
            SecurityMode        = 'SQL'
            SAPwd               = $SQLPassCredential
            SQLSysAdminAccounts = $SPInstallAccountCredential.UserName
            DependsOn           = "[Group]AdminGroup"
        }
        
        Package SSMS
        {
            Ensure      = "Present"
            Name        = "SMS-Setup-ENU"
            Path        = "C:\Install\SMS\SSMS-Setup-ENU.exe"
            Arguments   = "/install /passive /norestart"
            ProductId   = "6ce0f2ad-2643-496c-9b48-d0587d3e10a9"
            Credential  = $SPInstallAccountCredential
            DependsOn   = "[Group]AdminGroup"
        }
        
    }
}
