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
    Import-DSCResource -Module xSystemSecurity -Name xIEEsc
    Import-DscResource -ModuleName cChoco

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