Configuration SQLInstall
{
    param(
        $configParameters,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SQLPassCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $LocalAdminCredential,
        $machineName
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xNetworking -ModuleVersion 5.3.0.0
    Import-DsCResource -Module xWindowsUpdate -Name xHotfix -ModuleVersion 2.7.0.0
    Import-DscResource -ModuleName xPendingReboot -ModuleVersion 0.3.0.0
    Import-DSCResource -ModuleName xSQLServer -Name xSQLServerSetup -ModuleVersion 9.0.0.0

    Node $AllNodes.NodeName
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
        
        xHotfix RemoveKB2894856
        {
            Ensure  = "Absent"
            Path    = "C:/anyfolder/KB2894856.msu"
            Id      = "KB2894856"
        }

        xPendingReboot RebootBeforeNetFrameworkInstalling
        { 
            Name        = 'BeforeNetInstalling'
            DependsOn   = "[xHotfix]RemoveKB2894856"
        }


        # needed at least for Windows 2012 R2 and 2016
        WindowsFeature NetFramework35Core
        {
            Name                    = "NET-Framework-Core"
            IncludeAllSubFeature    = $true
            DependsOn               = "[xHotfix]RemoveKB2894856"
        }

        xPendingReboot RebootBeforeSQLInstalling
        { 
            Name        = 'BeforeSQLInstalling'
            DependsOn   = "[WindowsFeature]NetFramework35Core"
        }

        xSQLServerSetup SQLSetup
        {
            InstanceName        = "MSSQLServer"
            SourcePath          = $configParameters.SQLInstallationMediaPath
            Features            = "SQLENGINE,FULLTEXT"
            InstallSharedDir    = "C:\Program Files\Microsoft SQL Server"
            #Mixed authentication is needed for Access Services
            SecurityMode        = 'SQL'
            SQLSysAdminAccounts = "BUILTIN\Administrators"
            SAPwd               = $SQLPassCredential
            DependsOn           = "[WindowsFeature]NetFramework35Core"
        }

        <#
        if ( !( ( $configParameters.Machines | ? { $_.Name -eq $machineName } ).Roles -contains "AD" ) )
        {
            #Local DB admin group
            Group DBAdminGroup
            {
                GroupName           = "DBAdmins"
                Credential          = $LocalAdminCredential
                MembersToInclude    = "$machineName\$($LocalAdminCredential.UserName)"
            }

            $SQLSysAdminAccounts = "$machineName\DBAdmins"
            $SQLDependsOn = @( "[Group]DBAdminGroup", "[xPendingReboot]RebootBeforeSQLInstalling" )
        } else {
            $SQLSysAdminAccounts = "BUILTIN\Administrators"
            $SQLDependsOn = @( "[xPendingReboot]RebootBeforeSQLInstalling" )
        }

        xSQLServerSetup SQLSetup
        {
            InstanceName        = "MSSQLServer"
            SourcePath          = $configParameters.SQLInstallationMediaPath
            Features            = "SQLENGINE,FULLTEXT"
            InstallSharedDir    = "C:\Program Files\Microsoft SQL Server"
            #Mixed authentication is needed for Access Services
            SecurityMode        = 'SQL'
            SQLSysAdminAccounts = $SQLSysAdminAccounts
            SAPwd               = $SQLPassCredential
            DependsOn           = $SQLDependsOn
        }
        #>
        <#
        if ( !( ( $configParameters.Machines | ? { $_.Name -eq $machineName } ).Roles -contains "AD" ) )
        {
            $membersToInclude = "$machineName\$($LocalAdminCredential.UserName)"
        } else {
            $membersToInclude = "$machineName\Administrators"
        }
        Group DBAdminGroup
        {
            GroupName           = "DBAdmins"
            Credential          = $LocalAdminCredential
            MembersToInclude    = $membersToInclude
        }

        xSQLServerSetup SQLSetup
        {
            InstanceName        = "MSSQLServer"
            SourcePath          = $configParameters.SQLInstallationMediaPath
            Features            = "SQLENGINE,FULLTEXT"
            InstallSharedDir    = "C:\Program Files\Microsoft SQL Server"
            #Mixed authentication is needed for Access Services
            SecurityMode        = 'SQL'
            SQLSysAdminAccounts = "$machineName\DBAdmins"
            SAPwd               = $SQLPassCredential
            DependsOn           = @( "[Group]DBAdminGroup", "[xPendingReboot]RebootBeforeSQLInstalling" )
        }
        #>
    }
}

