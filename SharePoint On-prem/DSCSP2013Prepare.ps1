Configuration SP2013Prepare
{
    param(
        $configParameters
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -Module xSystemSecurity -Name xIEEsc
    Import-DsCResource -Module xWindowsUpdate -Name xHotfix
    Import-DscResource -ModuleName xPendingReboot

    Node $AllNodes.NodeName
    {
        #Only needed for manual mof installation, not for automated?
        <#
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
        #>
         
        Registry LoopBackRegistry
        {
            Ensure      = "Present"  # You can also set Ensure to "Absent"
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

        xPendingReboot RebootAfterNETUninstalling
        { 
            Name        = 'AfterNETUninstalling'
            DependsOn   = @( "[xHotfix]RemoveWin2012DotNet47", "[xHotfix]RemoveWin2012R2DotNet461", "[xHotfix]RemoveWin2012R2DotNet47" )
        }
        
    }
}
