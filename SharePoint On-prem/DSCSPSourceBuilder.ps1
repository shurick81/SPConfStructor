Configuration SPSourceBuilderRunner
{
    param(
        $configParameters        
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -Name xRemoteFile
    
    Node $AllNodes.NodeName
    {

    }
}
