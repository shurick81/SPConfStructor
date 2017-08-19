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
                        
        xRemoteFile SQLServerImageFile
        {
            DestinationPath = "C:\Install\SQLImage\SQLServer2014SP1-FullSlipstream-x64-ENU.iso"
            Uri = "http://care.dlservice.microsoft.com/dl/download/2/F/8/2F8F7165-BB21-4D1E-B5D8-3BD3CE73C77D/SQLServer2014SP1-FullSlipstream-x64-ENU.iso"
        }

        xMountImage SQLServerImageMount
        {
            ImagePath   = 'C:\Install\SQLImage\SQLServer2014SP1-FullSlipstream-x64-ENU.iso'
            DriveLetter = 'S'
            DependsOn   = @("[xRemoteFile]SQLServerImageFile")
        }

        xWaitForVolume WaitForSQLServerImageMount
        {
            DriveLetter         = 'S'
            RetryIntervalSec    = 5
            RetryCount          = 10
            DependsOn           = "[xMountImage]SQLServerImageMount"
        }

        File SQLServerInstallatorDirectory
        {
            Ensure          = "Present"
            Type            = "Directory"
            Recurse         = $true
            SourcePath      = "S:\"
            DestinationPath = "C:\Install\SQLExtracted"
            DependsOn       = "[xWaitForVolume]WaitForSQLServerImageMount"
        }
        # only for Windows 2012 R2? or Only for SQL 2014?
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
            DependsOn           = "[File]SQLServerInstallatorDirectory","[WindowsFeature]NetFramework35Core"
        }
        
    }
}

