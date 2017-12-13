Configuration SPOfficeTools
{
    param(
        $configParameters,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $UserCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -Module xSystemSecurity -Name xIEEsc -ModuleVersion 1.2.0.0
    Import-DscResource -ModuleName cChoco -ModuleVersion 2.3.1.0
    
    Node $AllNodes.NodeName
    {

        xIEEsc DisableIEEsc
        {
            IsEnabled   = $false
            UserRole    = "Administrators"
        }

        cChocoInstaller installChoco        
        {
            InstallDir = "c:\choco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller chocogooglechrome
        {
            Name        = "googlechrome"
            DependsOn   = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installoffice365proplus
        {
            Name        = "office365proplus"
            DependsOn   = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installonedrive
        {
            Name        = "onedrive"
            DependsOn   = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

    }
}