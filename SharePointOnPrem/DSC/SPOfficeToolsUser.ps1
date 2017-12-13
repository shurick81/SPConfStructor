Configuration SPOfficeToolsUser
{
    param(
        $configParameters,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $UserCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName cChoco -ModuleVersion 2.3.1.0
    
    Node $AllNodes.NodeName
    {

        cChocoInstaller installChoco        
        {
            InstallDir = "c:\choco"
            PsDscRunAsCredential    = $UserCredential
        }

        cChocoPackageInstaller installoffice365proplus
        {
            Name        = "office365proplus"
            DependsOn   = "[cChocoInstaller]installChoco"
            PsDscRunAsCredential    = $UserCredential
        }

    }
}