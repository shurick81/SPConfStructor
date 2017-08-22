Configuration SQL2014LoadingInstallationFiles
{
    param(
        $SQLImageUrl
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
    Import-DscResource -ModuleName xStorage

    $SQLMachineNames = $configParameters.Machines | ? { $_.Roles -contains "SQL" } | % { $_.Name }

    Node $SQLMachineNames
    {
        # Is it really needed when running via Azure Automation? or only manually
        $SQLImageUrl -match '[^/\\&\?]+\.\w{3,4}(?=([\?&].*$|$))' | Out-Null
        $SQLImageFileName = $matches[0]
        $SQLImageDestinationPath = "C:\Install\SQLImage\$SQLImageFileName"
        xRemoteFile SQLServerImageFile
        {
            Uri = $SQLImageUrl
            DestinationPath = $SQLImageDestinationPath
        }

        xMountImage SQLServerImageMount
        {
            ImagePath   = $SQLImageDestinationPath
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
    }
}

