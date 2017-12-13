Configuration SPDomain
{
    param(
        $configParameters,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $ShortDomainAdminCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $DomainSafeModeAdministratorPasswordCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPInstallAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPFarmAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPWebAppPoolAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPServicesAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPSearchServiceAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPCrawlerAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPOCAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPTestAccountCredential,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SPSecondTestAccountCredential,
        $machineName
    )

    $DomainName = $configParameters.DomainName;

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPendingReboot -ModuleVersion 0.3.0.0
    Import-DscResource -ModuleName xRemoteDesktopAdmin -ModuleVersion 1.1.0.0
    Import-DscResource -ModuleName xActiveDirectory -ModuleVersion 2.16.0.0
    
    Node $AllNodes.NodeName
    {

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }

        xADDomain ADDomain
        {
            DomainName                      = $DomainName
            DomainAdministratorCredential   = $ShortDomainAdminCredential
            SafemodeAdministratorPassword   = $DomainSafeModeAdministratorPasswordCredential
        }

        xWaitForADDomain WaitForDomain
        {
            DomainName              = $DomainName
            DomainUserCredential    = $ShortDomainAdminCredential
            RetryCount              = 100
            RetryIntervalSec        = 10
            DependsOn               = "[xADDomain]ADDomain"
        }

        xADUser SPInstallAccountUser
        {
            DomainName  = $DomainName
            UserName    = $SPInstallAccountCredential.GetNetworkCredential().UserName
            Password    = $SPInstallAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPFarmAccountUser
        {
            DomainName  = $DomainName
            UserName    = $SPFarmAccountCredential.GetNetworkCredential().UserName
            Password    = $SPFarmAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPWebAppPoolAccountUser
        {
            DomainName  = $DomainName
            UserName    = $SPWebAppPoolAccountCredential.GetNetworkCredential().UserName
            Password    = $SPWebAppPoolAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPServicesAccountUser
        {
            DomainName  = $DomainName
            UserName    = $SPServicesAccountCredential.GetNetworkCredential().UserName
            Password    = $SPServicesAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPSearchServiceAccountUser
        {
            DomainName  = $DomainName
            UserName    = $SPSearchServiceAccountCredential.GetNetworkCredential().UserName
            Password    = $SPSearchServiceAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPCrawlerAccountUser
        {
            DomainName  = $DomainName
            UserName    = $SPCrawlerAccountCredential.GetNetworkCredential().UserName
            Password    = $SPCrawlerAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPOCSuperUserADUser
        {
            DomainName  = $DomainName
            UserName    = $configParameters.SPOCSuperUser
            Password    = $SPOCAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPOCSuperReaderUser
        {
            DomainName  = $DomainName
            UserName    = $configParameters.SPOCSuperReader
            Password    = $SPOCAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPTestUser
        {
            DomainName  = $DomainName
            UserName    = $SPTestAccountCredential.GetNetworkCredential().UserName
            Password    = $SPTestAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADUser SPSecondTestUser
        {
            DomainName  = $DomainName
            UserName    = $SPSecondTestAccountCredential.GetNetworkCredential().UserName
            Password    = $SPSecondTestAccountCredential
            DependsOn   = "[xWaitForADDomain]WaitForDomain"
        }

        xADGroup SPAdminGroup
        {
            GroupName           = $configParameters.SPAdminGroupName
            MembersToInclude    = $SPInstallAccountCredential.GetNetworkCredential().UserName
            DependsOn           = "[xADUser]SPInstallAccountUser"
        }

        xADGroup DomainDBAdminGroup
        {
            GroupName           = $configParameters.SQLAdminGroupName
            Members             = $SPInstallAccountCredential.GetNetworkCredential().UserName
            DependsOn           = "[xADUser]SPInstallAccountUser"
        }

        xADGroup DomainAdminGroup
        {
            GroupName           = "Domain Admins"
            MembersToInclude    = $SPInstallAccountCredential.GetNetworkCredential().UserName
            DependsOn           = "[xADUser]SPInstallAccountUser"
        }

        <#
        $domainAdminsMembersToInclude = @()
        if ( ( $configParameters.Machines | ? { $_.Name -eq $machineName } ).Roles -contains "SQL" )
        {
            $domainAdminsMembersToInclude += $configParameters.SQLAdminGroupName
        }
        if ( ( $configParameters.Machines | ? { $_.Name -eq $machineName } ).Roles -contains "SharePoint" )
        {
            $domainAdminsMembersToInclude += $configParameters.SPAdminGroupName
        }
        if ( $domainAdminsMembersToInclude.Count -gt 0 )
        {
       
            xADGroup DomainAdminGroup
            {
                GroupName           = "Domain Admins"
                MembersToInclude    = $domainAdminsMembersToInclude
                DependsOn           = @( "[xADGroup]SPAdminGroup", "[xADGroup]DomainDBAdminGroup" )
            }

        }
        #>

        xADGroup SPMemberGroup
        {
            GroupName           = $configParameters.SPMemberGroupName
            Ensure              = "Present"
            MembersToInclude    = $SPTestAccountCredential.GetNetworkCredential().UserName
            DependsOn           = "[xADUser]SPTestUser"
        }

        xADGroup SPVisitorGroup
        {
            GroupName           = $configParameters.SPVisitorGroupName
            Ensure              = "Present"
            MembersToInclude    = $SPSecondTestAccountCredential.GetNetworkCredential().UserName
            DependsOn           = "[xADUser]SPSecondTestUser"
        }
    }
}