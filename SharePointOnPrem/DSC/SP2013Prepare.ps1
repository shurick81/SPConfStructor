Configuration SP2013Prepare
{
    param(
        $configParameters
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -Module xSystemSecurity -Name xIEEsc -ModuleVersion 1.2.0.0
    Import-DsCResource -Module xWindowsUpdate -Name xHotfix -ModuleVersion 2.7.0.0
    Import-DscResource -ModuleName xPendingReboot -ModuleVersion 0.3.0.0

    Node $AllNodes.NodeName
    {
        
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
         
        Registry LoopBackRegistry
        {
            Ensure      = "Present"
            Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName   = "DisableLoopbackCheck"
            ValueType   = "DWORD"
            ValueData   = "1"
        }

        xIEEsc DisableIEEsc
        {
            IsEnabled   = $false
            UserRole    = "Administrators"
        }

        #azure Win 2012
        xHotfix RemoveWin2012DotNet47
        {
            Ensure  = "Absent"
            Path    = "C:/anyfolder/KB3186505.msu"
            Id      = "KB3186505"
        }

        #azure Win 2012 R2
        xHotfix RemoveWin2012R2DotNet461
        {
            Ensure  = "Absent"
            Path    = "C:/anyfolder/KB3102467.msu"
            Id      = "KB3102467"
        }

        #azure Win 2012 R2
        xHotfix RemoveWin2012R2DotNet47
        {
            Ensure  = "Absent"
            Path    = "C:/anyfolder/KB3186539.msu"
            Id      = "KB3186539"
        }

        <#
        xPendingReboot RebootAfterNETUninstalling
        { 
            Name        = 'AfterNETUninstalling'
            DependsOn   = @( "[xHotfix]RemoveWin2012DotNet47", "[xHotfix]RemoveWin2012R2DotNet461", "[xHotfix]RemoveWin2012R2DotNet47" )
        }
        #>

        $resourceCounter = 0;
        @("Net-Framework-Features",
        "Web-Server",
        "Web-WebServer",
        "Web-Common-Http",
        "Web-Static-Content",
        "Web-Default-Doc",
        "Web-Dir-Browsing",
        "Web-Http-Errors",
        "Web-App-Dev",
        "Web-Asp-Net",
        "Web-Net-Ext",
        "Web-ISAPI-Ext",
        "Web-ISAPI-Filter",
        "Web-Health",
        "Web-Http-Logging",
        "Web-Log-Libraries",
        "Web-Request-Monitor",
        "Web-Http-Tracing",
        "Web-Security",
        "Web-Basic-Auth",
        "Web-Windows-Auth",
        "Web-Filtering",
        "Web-Digest-Auth",
        "Web-Performance",
        "Web-Stat-Compression",
        "Web-Dyn-Compression",
        "Web-Mgmt-Tools",
        "Web-Mgmt-Console",
        "Web-Mgmt-Compat",
        "Web-Metabase",
        "Application-Server",
        "AS-Web-Support",
        "AS-TCP-Port-Sharing",
        "AS-WAS-Support",
        "AS-HTTP-Activation",
        "AS-TCP-Activation",
        "AS-Named-Pipes",
        "AS-Net-Framework",
        "WAS",
        "WAS-Process-Model",
        "WAS-NET-Environment",
        "WAS-Config-APIs",
        "Web-Lgcy-Scripting",
        "Windows-Identity-Foundation",
        "Server-Media-Foundation",
        "Xps-Viewer") | % {

            WindowsFeature "SPPrerequisiteFeature$resourceCounter"
            {
                Name = $_
                Ensure = "Present"
            }

            $resourceCounter++;
        }

    }
}
