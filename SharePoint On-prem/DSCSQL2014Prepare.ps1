Configuration SQL2014Prepare
{
    param(
        $configParameters
    )
    $SQLPass = $configParameters.SQLPass;


    # examining, generating and requesting credentials
    
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
    Import-DSCResource -ModuleName xNetworking
    Import-DscResource -ModuleName xStorage
    Import-DSCResource -ModuleName xSQLServer -Name xSQLServerSetup

    $SQLMachineNames = $configParameters.Machines | ? { $_.Roles -contains "SQL" } | % { $_.Name }

    Node $SQLMachineNames
    {
        # Is it really needed when running via Azure Automation? or only manually
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
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
                
        # needed at least for Windows 2012 R2 and 2016
        WindowsFeature NetFramework35Core
        {
            Name = "NET-Framework-Core"
            Ensure = "Present"
        }

        xSQLServerSetup SQLSetup
        {
            InstanceName        = "MSSQLServer"
            SourcePath          = "C:\Install\SQLExtracted"
            Features            = "SQLENGINE,FULLTEXT,SSMS"
            InstallSharedDir    = "C:\Program Files\Microsoft SQL Server"
            #Mixed authentication is needed for Access Services
            SecurityMode        = 'SQL'
            SQLSysAdminAccounts = 'Builtin\Administrators'
            SAPwd               = $SQLPassCredential
            DependsOn           = "[WindowsFeature]NetFramework35Core"
        }
        
    }
}

