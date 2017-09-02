Configuration SP2016Prepare
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
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true;
        }
         
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
        
    }
}
