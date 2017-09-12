<#
.SYNOPSIS
    Builds a SharePoint 2010/2013/2016 Service Pack + Cumulative/Public Update slipstreamed installation source.
.DESCRIPTION
    Starting from existing (user-provided) SharePoint 2010/2013/2016 installation media/files (and optionally Office Web Apps / Online Server media/files),
    the script can download the prerequisites, specified Service Pack and CU/PU packages for SharePoint/WAC, along with specified (optional) language packs, then extract them to a destination path structure.
    Uses the AutoSPSourceBuilder.XML file as the source of product information (URLs, builds, naming, etc.) and requires it to be present in the same folder as the AutoSPSourceBuilder.ps1 script.
.EXAMPLE
    AutoSPSourceBuilder.ps1 -UpdateLocation "C:\Users\brianl\Downloads\SP" -Destination "D:\SP\2010"
.EXAMPLE
    AutoSPSourceBuilder.ps1 -SourceLocation E: -Destination "C:\Source\SP\2010" -CumulativeUpdate "December 2011" -Languages fr-fr,es-es
.PARAMETER SourceLocation
    The location (path, drive letter, etc.) where the SharePoint binary files are located.
    You can specify a UNC path (\\server\share\SP\2010), a drive letter (E:) or a local/mapped folder (Z:\SP\2010).
    If you don't provide a value, the script will check every possible drive letter for a mounted DVD/ISO.
.PARAMETER Destination
    The file path for the final slipstreamed SP2010/SP2013/2016 installation files.
    The default value is $env:SystemDrive\SP\2010 (so in most cases, C:\SP\2010).
.PARAMETER UpdateLocation
    The file path where the downloaded service pack and cumulative update files are located, or where they should be saved in case they need to be downloaded.
    The default value is the subfolder <Destination>\Updates (so, typically C:\SP\201x\Updates).
.PARAMETER GetPrerequisites
    Specifies whether to attempt to download all prerequisite files for the selected product, which can be subsequently used to perform an offline installation.
    The default value is $false.
.PARAMETER CumulativeUpdate
    The name of the cumulative update (CU) you'd like to integrate.
    The format should be e.g. "December 2011".
    If no value is provided, the script will prompt for an available CU name.
.PARAMETER WACSourceLocation
    The location (path, drive letter, etc.) where the Office Web Apps / Online Server binary files are located.
    You can specify a UNC path (\\server\share\SP\2010), a drive letter (E:) or a local/mapped folder (Z:\WAC).
    If no value is provided, the script will simply skip the WAC integration altogether.
.PARAMETER Languages
    A comma-separated list of languages (in the culture ID format, e.g. de-de,fr-fr) used to specify which language packs to download.
    If no languages are provided, the script will simply skip language pack integration altogether.
.LINK
    https://github.com/brianlala/autospsourcebuilder
    http://autospsourcebuilder.codeplex.com
    http://autospinstaller.codeplex.com
    http://www.toddklindt.com/sp2010builds
.NOTES
    Created & maintained by Brian Lalancette (@brianlala), 2012-2016.
#>
param
(
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    [String]$SourceLocation,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    [String]$Destination = $env:SystemDrive+"\SP\2010",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    [String]$UpdateLocation,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    [Switch]$GetPrerequisites,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    [String]$CumulativeUpdate,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    [String]$WACSourceLocation,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    [Array]$Languages
)

#region Pause Function
# ===================================================================================
# Func: Pause
# Desc: Wait for user to press a key - normally used after an error has occured or input is required
# ===================================================================================
Function Pause($action, $key)
{
    # From http://www.microsoft.com/technet/scriptcenter/resources/pstips/jan08/pstip0118.mspx
    if ($key -eq "any" -or ([string]::IsNullOrEmpty($key)))
    {
        $actionString = "Press any key to $action..."
        Write-Host $actionString
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    else
    {
        $actionString = "Enter `"$key`" to $action"
        $continue = Read-Host -Prompt $actionString
        if ($continue -ne $key) {pause $action $key}

    }
}
#endregion

# First check if we are running this under an elevated session. Pulled from the script at http://gallery.technet.microsoft.com/scriptcenter/1b5df952-9e10-470f-ad7c-dc2bdc2ac946
If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning " - You must run this script under an elevated PowerShell prompt. Launch an elevated PowerShell prompt by right-clicking the PowerShell shortcut and selecting `"Run as Administrator`"."
    break
}

# Then check if we are running Server 2012, Windows 8 or newer (e.g. Windows 10)
$windowsMajorVersion,$windowsMinorVersion,$null = (Get-WmiObject Win32_OperatingSystem).Version -split "\."
if (($windowsMajorVersion -lt 6 -or (($windowsMajorVersion -eq 6) -and ($windowsMinorVersion -lt 2)) -and $windowsMajorVersion -ne 10) -and ($Languages.Count -gt 0))
{
    Write-Warning "You should be running Windows Server 2012 or Windows 8 (minimum) to get the full functionality of this script."
    Write-Host -ForegroundColor Yellow " - Some features (e.g. image extraction) may not work otherwise."
    Pause "proceed if you are sure this is OK, or Ctrl-C to exit" "y"
}

<#
$oldTitle = $Host.UI.RawUI.WindowTitle
$Host.UI.RawUI.WindowTitle = " -- AutoSPSourceBuilder --"
#>
$0 = $myInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)

# Only needed if proxy is enabled
# $proxyCredentials = (Get-Credential -Message "Enter credentials for proxy server:" -UserName "$env:USERDOMAIN\$env:USERNAME")

Write-Host -ForegroundColor Green " -- AutoSPSourceBuilder SharePoint Update Slipstreaming Utility --"

[xml]$xml = (Get-Content -Path "$dp0\AutoSPSourceBuilder.xml")

#region Functions
Function WriteLine
{
    Write-Host -ForegroundColor White "--------------------------------------------------------------"
}

Function DownloadPackage ($url, $ExpandedFile, $DestinationFolder, $destinationFile)
{
    $ExpandedFileExists = $false
    $file = $url.Split('/')[-1]
    If (!$destinationFile) {$destinationFile = $file}
    If (!$expandedFile) {$expandedFile = $file}
    Try
    {
        # Check if destination file or its expanded version already exists
        If (Test-Path "$DestinationFolder\$expandedFile") # Check if the expanded file is already there
        {
            Write-Host -ForegroundColor DarkGray "  - File $expandedFile exists, skipping download."
            $expandedFileExists = $true
        }
        ElseIf ((($file -eq $destinationFile) -or ("$file.zip" -eq $destinationFile)) -and ((Test-Path "$DestinationFolder\$file") -or (Test-Path "$DestinationFolder\$file.zip")) -and !((Get-Item $file -ErrorAction SilentlyContinue).Mode -eq "d----")) # Check if the packed downloaded file is already there (in case of a CU or Prerequisite)
        {
            Write-Host -ForegroundColor DarkGray "  - File $file exists, skipping download."
            If (!($file -like "*.zip"))
            {
                # Give the CU package a .zip extension so we can work with it like a compressed folder
                Rename-Item -Path "$DestinationFolder\$file" -NewName ($file+".zip") -Force -ErrorAction SilentlyContinue
            }
        }
        ElseIf (Test-Path "$DestinationFolder\$destinationFile") # Check if the packed downloaded file is already there (in case of a CU)
        {
            Write-Host -ForegroundColor DarkGray "  - File $destinationFile exists, skipping download."
        }
        Else # Go ahead and download the missing package
        {
            # Begin download
            Import-Module BitsTransfer
            $job = Start-BitsTransfer -Asynchronous -Source $url -Destination "$DestinationFolder\$destinationFile" -DisplayName "Downloading `'$file`' to $DestinationFolder\$destinationFile" -Priority Foreground -Description "From $url..." -RetryInterval 60 -RetryTimeout 3600 -ErrorVariable err
            # When proxy is enabled
            # $job = Start-BitsTransfer -Asynchronous -Source $url -Destination "$DestinationFolder\$destinationFile" -DisplayName "Downloading `'$file`' to $DestinationFolder\$destinationFile" -Priority Foreground -Description "From $url..." -RetryInterval 60 -RetryTimeout 3600 -ProxyList canatsrv06:80 -ProxyUsage Override -ProxyAuthentication Ntlm -ProxyCredential $proxyCredentials -ErrorVariable err
            Write-Host "  - Connecting..." -NoNewline
            while ($job.JobState -eq "Connecting")
            {
                Write-Host "." -NoNewline
                Start-Sleep -Milliseconds 500
            }
            Write-Host "."
            If ($err) {Throw ""}
            Write-Host "  - Downloading $file..."
            while ($job.JobState -ne "Transferred")
            {
                $percentDone = "{0:N2}" -f $($job.BytesTransferred / $job.BytesTotal * 100) + "% - $($job.JobState)"
                Write-Host $percentDone -NoNewline
                Start-Sleep -Milliseconds 500
                $backspaceCount = (($percentDone).ToString()).Length
                for ($count = 0; $count -le $backspaceCount; $count++) {Write-Host "`b `b" -NoNewline}
                if ($job.JobState -like "*Error")
                {
                    Write-Host -ForegroundColor Yellow "  - An error occurred downloading $file, retrying..."
                    Resume-BitsTransfer -BitsJob $job -Asynchronous | Out-Null
                }
            }
            Write-Host "  - Completing transfer..."
            Complete-BitsTransfer -BitsJob $job
            Write-Host " - Done!"
        }
    }
    Catch
    {
        Write-Warning " - An error occurred downloading `'$file`'"
        $errorWarning = $true
        break
    }
}

Function Expand-Zip ($InputFile, $DestinationFolder)
{
    $Shell = New-Object -ComObject Shell.Application
    $fileZip = $Shell.Namespace($InputFile)
    $Location = $Shell.Namespace($DestinationFolder)
    $Location.Copyhere($fileZip.items())
}

Function Read-Log()
{
    $log = Get-ChildItem -Path (Get-Item $env:TEMP).FullName | Where-Object {$_.Name -like "opatchinstall*.log"} | Sort-Object -Descending -Property "LastWriteTime" | Select-Object -first 1
    If ($log -eq $null)
    {
        Write-Host `n
        Throw " - Could not find extraction log file!"
    }
    # Get error(s) from log
    $lastError = $log | select-string -SimpleMatch -Pattern "OPatchInstall: The extraction of the files failed" | Select-Object -Last 1
    If ($lastError)
    {
        Write-Host `n
        Write-Warning $lastError.Line
        $errorWarning = $true
        Invoke-Item $log.FullName
        Throw " - Review the log file and try to correct any error conditions."
    }
    Remove-Variable -Name log
}

Function Remove-ReadOnlyAttribute ($Path)
{
    ForEach ($item in (Get-ChildItem -File -Path $Path -Recurse -ErrorAction SilentlyContinue))
    {
        $attributes = @((Get-ItemProperty -Path $item.FullName).Attributes)
        If ($attributes -match "ReadOnly")
        {
            # Set the file to just have the 'Archive' attribute
            Write-Host "  - Removing Read-Only attribute from file: $item"
            Set-ItemProperty -Path $item.FullName -Name Attributes -Value "Archive"
        }
    }
}

# ====================================================================================
# Func: EnsureFolder
# Desc: Checks for the existence and validity of a given path, and attempts to create if it doesn't exist.
# From: Modified from patch 9833 at http://autospinstaller.codeplex.com/SourceControl/list/patches by user timiun
# ====================================================================================
Function EnsureFolder ($Path)
{
        If (!(Test-Path -Path $Path -PathType Container))
        {
            Write-Host -ForegroundColor White " - $Path doesn't exist; creating..."
            Try
            {
                New-Item -Path $Path -ItemType Directory | Out-Null
            }
            Catch
            {
                Write-Warning " - $($_.Exception.Message)"
                Throw " - Could not create folder $Path!"
                $errorWarning = $true
            }
        }
}

#endregion

#region Determine product version and languages requested
if ($SourceLocation)
{
    $sourceDir = $SourceLocation.TrimEnd("\")
    Write-Host " - Checking for $sourceDir\Setup.exe and $sourceDir\PrerequisiteInstaller.exe..."
    $sourceFound = ((Test-Path -Path "$sourceDir\Setup.exe") -and (Test-Path -Path "$sourceDir\PrerequisiteInstaller.exe"))
}
# Inspired by http://vnucleus.com/2011/08/alphabet-range-sequences-in-powershell-and-a-usage-example/
while (!$sourceFound)
{
    foreach ($driveLetter in 68..90) # Letters from D-Z
    {
        # Check for the SharePoint DVD in all possible drive letters
        $sourceDir = "$([char]$driveLetter):"
        Write-Host " - Checking for $sourceDir\Setup.exe and $sourceDir\PrerequisiteInstaller.exe..."
        $sourceFound = ((Test-Path -Path "$sourceDir\Setup.exe") -and (Test-Path -Path "$sourceDir\PrerequisiteInstaller.exe"))
        If ($sourceFound -or $driveLetter -ge 90) {break}
    }
    break
}
if (!$sourceFound)
{
    Write-Warning " - The correct SharePoint source files/media were not found!"
    Write-Warning " - Please insert/mount the correct media, or specify a valid path."
    $errorWarning = $true
    break
    Pause "exit"
    exit
}
else
{
    Write-Host " - Source found in $sourceDir."
    $spVer,$null = (Get-Item -Path "$sourceDir\setup.exe").VersionInfo.ProductVersion -split "\."
    If (!$sourceDir) {Write-Warning " - Cannot determine version of SharePoint setup binaries."; $errorWarning = $true; break; Pause "exit"; exit}
    # Create a hash table with 'wave' to product year mappings
    $spYears = @{"14" = "2010"; "15" = "2013"; "16" = "2016"}
    $spYear = $spYears.$spVer
    Write-Host " - SharePoint $spYear detected."
    if ($spYear -eq "2013" -or $spYear -eq "2016")
    {
        $Destination = $Destination -replace "2010",$spYear
        if ($spYear -eq "2013")
        {
            $installerVer = (Get-Command "$sourceDir\setup.dll").FileVersionInfo.ProductVersion
            $null,$null,[int]$build,$null = $installerVer -split "\."
            If ($build -ge 4569) # SP2013 SP1
            {
                $sp2013SP1 = $true
                Write-Host "  - Service Pack 1 detected."
            }
        }
    }

    $Destination = $Destination.TrimEnd("\")
    # Ensure the Destination has the year at the end of the path, in case we forgot to type it in when/if prompted
    if (!($Destination -like "*$spYear"))
    {
        $Destination = $Destination+"\"+$spYear
    }
    if ([string]::IsNullOrEmpty($UpdateLocation))
    {
        $UpdateLocation = $Destination+"\Updates"
    }
    if ($Languages.Count -gt 0)
    {
        # Remove any spaces or quotes and ensure each one is split out
        [array]$languages = $Languages -replace ' ','' -split "," ## -replace '"',''
        Write-Host " - Languages requested:"
        foreach ($language in $Languages)
        {
            Write-Host "  - $language"
        }
    }
    else {Write-Host " - No languages specified on the command line."}
}
#endregion

$spNode = $xml.Products.Product | Where-Object {$_.Name -eq "SP$spYear"}
# Figure out which CU we want, but only if there are any available
[array]$spCuNodes = $spNode.CumulativeUpdates.ChildNodes | Where-Object {$_.NodeType -ne "Comment"}
if ((!([string]::IsNullOrEmpty($CumulativeUpdate))) -and !($spNode.CumulativeUpdates.CumulativeUpdate | Where-Object {$_.Name -eq $CumulativeUpdate}))
{
    Write-Warning " - Invalid entry for update: `"$CumulativeUpdate`""
    Remove-Variable -Name CumulativeUpdate
}
while (([string]::IsNullOrEmpty($CumulativeUpdate)) -and (($spCuNodes).Count -ge 1))
{
    Write-Host " - Please select an available $(if ($spYear -eq "2016") {"Public"} else {"Cumulative"}) Update from the list that appears..."
    Start-Sleep 2
    $CumulativeUpdate =  $spNode.CumulativeUpdates.CumulativeUpdate.Name | Select-Object -Unique | Out-GridView -Title "Please select an available CU/PU:" -PassThru
    if ($CumulativeUpdate.Count -gt 1)
    {
        Write-Warning "Please only select ONE update."
        Remove-Variable -Name CumulativeUpdate -Force
    }
}
[array]$spCU = $spNode.CumulativeUpdates.CumulativeUpdate | Where-Object {$_.Name -eq $CumulativeUpdate}
if ($spCU.Count -ge 1) # Only do this stuff if we actually have requested a CU
{
    $spCUName = $spCU[0].Name
    $spCUBuild = $spCU[0].Build
    if ($spYear -eq "2010") # For SP2010 service packs
    {
        $null,$null,$updateSubBuild,$null = $spCU[0].Build -split "\."
        # Get the service pack required, based on the sp* value in the CU URL - the URL will refer to the *upcoming* service pack and not the service pack required to apply the CU...
        if ($spCU[0].Url -like "*sp2*" -and $CumulativeUpdate -ne "August 2013" -and $CumulativeUpdate -ne "October 2013") # As we would probably want at least SP1 if we are installing a CU prior to the August 2013 CU for SP2010
        {
            $spServicePack = $spNode.ServicePacks.ServicePack | Where-Object {$_.Name -eq "SP1"}
        }
        elseif ($spCU[0].Url -like "*sp3*" -or $CumulativeUpdate -eq "August 2013" -or $updateSubBuild -gt 7140) # We probably want SP2 if we are installing the August 2013 CU for SP2010, or a version newer than 14.0.7140.5000
        {
            $spServicePack = $spNode.ServicePacks.ServicePack | Where-Object {$_.Name -eq "SP2"}
        }
    }
    elseif ($spYear -eq "2013") # For SP2013 service packs
    {
        if ($sp2013SP1)
        {
            $spServicePack = $spNode.ServicePacks.ServicePack | Where-Object {$_.Name -eq "SP1"}
        }
    }
    # Check if we are requesting the August 2014 CU, which sure enough, isn't cumulative and requires SP1 + July 2014 CU
    if ($CumulativeUpdate -eq "August 2014")
    {
        Write-Host " - The $CumulativeUpdate CU requires the July 2014 CU to be present first; will now attempt to integrate both."
        [array]$spCU = ($spNode.CumulativeUpdates.CumulativeUpdate | Where-Object {$_.Name -eq "July 2014"}), $spCU
    }
}

#region SharePoint Source Binaries
if (!($sourceDir -eq "$Destination\SharePoint"))
{
    WriteLine
    Write-Host " - (Robo-)copying files from $sourceDir to $Destination\SharePoint..."
    Start-Process -FilePath robocopy.exe -ArgumentList "`"$sourceDir`" `"$Destination\SharePoint`" /E /Z /ETA /NDL /NFL /NJH /XO /A-:R" -Wait -NoNewWindow
    Write-Host " - Done copying original files to $Destination\SharePoint."
    WriteLine
}
#endregion

#region SharePoint Prerequisites
If ($GetPrerequisites)
{
    WriteLine
    $spPrerequisiteNode = $spNode.Prerequisites
    foreach ($prerequisite in $spPrerequisiteNode.Prerequisite)
    {
        Write-Host " - Getting prerequisite `"$($prerequisite.Name)`"..."
        # Because MS added a newer WcfDataServices.exe (yes, with the same filename) to the prerequisites list with SP2013 SP1, we need a special case here to ensure it's downloaded with a different name
        if ($prerequisite.Name -eq "Microsoft WCF Data Services 5.6" -and $spYear -eq "2013")
        {
            DownloadPackage -Url $($prerequisite.Url) -ExpandedFile "WcfDataServices56.exe" -DestinationFolder "$Destination\SharePoint\PrerequisiteInstallerFiles" -DestinationFile "WcfDataServices56.exe"
        }
        else
        {
            DownloadPackage -Url $($prerequisite.Url) -DestinationFolder "$Destination\SharePoint\PrerequisiteInstallerFiles"
        }
    }
    # Apply KB3087184 for SharePoint 2013 installer
    # KB3087184 can be considered a "prerequisite" for successful installation of SharePoint 2013 on a server that already has the .Net Framework 4.6 installed
    If ($spYear -eq "2013")
    {
        Write-Host " - Checking version of `"$Destination\SharePoint\svrsetup.dll`"..."
        # Check to see if we have already patched/replaced svrsetup.dll
        $null,$null,[int]$svrSetupDllBuild,$null = (Get-Item -Path "$Destination\SharePoint\svrsetup.dll" -ErrorAction SilentlyContinue).VersionInfo.ProductVersion -split "\."
        if ($null -eq $svrSetupDllBuild)
        {
            Write-Host -ForegroundColor Yellow " - `"$Destination\SharePoint\svrsetup.dll` was not found (or version could not be determined); skipping."
        }
        else
        {
            # Check for presence and version of svrsetup.dll
            if ($svrSetupDllBuild -lt 4709) # 4709 is the version substring/build of the patched svrsetup.dll
            {
                if (Test-Path -Path "$Destination\SharePoint\PrerequisiteInstallerFiles\svrsetup_15-0-4709-1000_x64.zip" -ErrorAction SilentlyContinue)
                {
                    Write-Host "  - Attempting to patch SharePoint 2013 installation source with updated svrsetup.dll from KB3087184..."
                    # Rename the original file
                    Write-Host "  - Replacing `"$Destination\SharePoint\svrsetup.dll`" with updated version from KB3087184..."
                    Write-Host "   - Renaming existing file..."
                    Rename-Item -Path "$Destination\SharePoint\svrsetup.dll" -NewName "svrsetup.original.dll" -Confirm:$false
                    Write-Host "   - Copying new version of svrsetup.dll..."
                    Expand-Zip -InputFile "$Destination\SharePoint\PrerequisiteInstallerFiles\svrsetup_15-0-4709-1000_x64.zip" -DestinationFolder "$Destination\SharePoint"
                    Write-Host " - Done."
                    $patchedForKB3087184 = $true
                }
                else
                {
                    Write-Host -ForegroundColor Yellow "  - Package for KB3087184 was not found; skipping patching of SharePoint $spVer installation source."
                }
            }
            else
            {
                Write-Host -ForegroundColor DarkGray "  - `"$Destination\SharePoint\svrsetup.dll`" is already updated ($svrSetupDllBuild)."
                $patchedForKB3087184 = $true
            }
        }
    }
    WriteLine
}
#endregion

#region Prompt for Language Packs
if ($Languages.Count -eq 0)
{
    $lpNode = $spNode.LanguagePacks
    # Prompt for an available language pack
    $availableLanguageNames = $lpNode.LanguagePack | Where-Object {$null -ne $_.Url} | Select-Object Name | Sort-Object Name
    Write-Host " - Please select an available language pack from the list that appears..."
    [array]$Languages = $availableLanguageNames.Name | Out-GridView -Title "Please select an available language pack. Hold down Ctrl to select multiple, or click Cancel to skip):" -PassThru
    if ($Languages.Count -eq 0)
    {
        Write-Host " - No languages selected."
    }
    else
    {
        # Remove any spaces or quotes and ensure each one is split out
        [array]$languages = $Languages -replace ' ','' -split ","
        Write-Host " - Languages requested:"
        foreach ($language in $Languages)
        {
            Write-Host "  - $language"
        }
    }
}
#endregion

#region Download & slipstream SharePoint Service Pack
If ($spServicePack -and ($spYear -ne "2013")) # Exclude SharePoint 2013 service packs as slipstreaming support has changed
{
    if ($spServicePack.Name -eq "SP1" -and $spYear -eq "2010") {$spMspCount = 40} # Service Pack 1 should have 40 .msp files
    if ($spServicePack.Name -eq "SP2" -and $spYear -eq "2010") {$spMspCount = 47} # Service Pack 2 should have 47 .msp files
    else {$spMspCount = 0}
    WriteLine
    # Check if a SharePoint service pack already appears to be included in the source
    If ((Get-ChildItem "$sourceDir\Updates" -Filter *.msp).Count -lt $spMspCount) # Checking for specific number of MSP patch files in the \Updates folder
    {
        Write-Host " - $($spServicePack.Name) seems to be missing, or incomplete in $sourceDir\; downloading..."
        # Set the subfolder name for easy update build & name identification, for example, "15.0.4481.1005 (March 2013)"
        $spServicePackSubfolder = $spServicePack.Build+" ("+$spServicePack.Name+")"
        EnsureFolder "$UpdateLocation\$spServicePackSubfolder"
        DownloadPackage -Url $($spServicePack.Url) -DestinationFolder "$UpdateLocation\$spServicePackSubfolder"
        Remove-ReadOnlyAttribute -Path "$Destination\SharePoint\Updates"
        # Extract SharePoint service pack patch files
        Write-Host " - Extracting SharePoint $($spServicePack.Name) patch files..." -NoNewline
        $spServicePackExpandedFile = $($spServicePack.Url).Split('/')[-1]
        Start-Process -FilePath "$UpdateLocation\$spServicePackSubfolder\$spServicePackExpandedFile" -ArgumentList "/extract:`"$Destination\SharePoint\Updates`" /passive" -Wait -NoNewWindow
        Read-Log
        Write-Host "done!"
    }
    Else {Write-Host " - $($spServicePack.Name) appears to be already slipstreamed into the SharePoint binary source location."}

    ## Extract SharePoint w/SP1 files (future functionality?)
    ## Start-Process -FilePath "$UpdateLocation\en_sharepoint_server_2010_with_service_pack_1_x64_759775.exe" -ArgumentList "/extract:$Destination\SharePoint /passive" -NoNewWindow -Wait -NoNewWindow
    WriteLine
}
#endregion

#region Download & slipstream March PU for SharePoint 2013
# Since the March 2013 PU for SharePoint 2013 is considered the baseline build for all patches going forward (prior to SP1), we need to download and extract it if we are looking for a SP2013 CU dated March 2013 or later
If ($spCU.Count -ge 1 -and $spCU[0].Name -ne "December 2012" -and $spYear -eq "2013" -and !$sp2013SP1)
{
    WriteLine
    $march2013PU = $spNode.CumulativeUpdates.CumulativeUpdate | Where-Object {$_.Name -eq "March 2013"}
    Write-Host " - Getting SharePoint $spYear baseline update $($march2013PU.Name) PU:"
    $march2013PUFile = $($march2013PU.Url).Split('/')[-1]
    if ($march2013PU.Url -like "*zip.exe")
    {
        $march2013PUFileIsZip = $true
        $march2013PUFile += ".zip"
    }
    # Set the subfolder name for easy update build & name identification, for example, "15.0.4481.1005 (March 2013)"
    $updateSubfolder = $march2013PU.Build+" ("+$march2013PU.Name+")"
    EnsureFolder "$UpdateLocation\$updateSubfolder"
    DownloadPackage -Url $($march2013PU.Url) -ExpandedFile $($march2013PU.ExpandedFile) -DestinationFolder "$UpdateLocation\$updateSubfolder" -destinationFile $march2013PUFile
    # Expand PU executable to $UpdateLocation\$updateSubfolder
    If (!(Test-Path "$UpdateLocation\$updateSubfolder\$($march2013PU.ExpandedFile)") -and $march2013PUFileIsZip) # Ensure the expanded file isn't already there, and the PU is a zip
    {
        $march2013PUFileZipPath = Join-Path -Path "$UpdateLocation\$updateSubfolder" -ChildPath $march2013PUFile
        Write-Host " - Expanding $($march2013PU.Name) Public Update (single file)..."
        # Remove any pre-existing hotfix.txt file so we aren't prompted to replace it by Expand-Zip and cause our script to pause
        if (Test-Path -Path "$UpdateLocation\$updateSubfolder\hotfix.txt" -ErrorAction SilentlyContinue)
        {
            Remove-Item -Path "$UpdateLocation\$updateSubfolder\hotfix.txt" -Confirm:$false -ErrorAction SilentlyContinue
        }
        Expand-Zip -InputFile $march2013PUFileZipPath -DestinationFolder "$UpdateLocation\$updateSubfolder"
    }
    Remove-ReadOnlyAttribute -Path "$Destination\SharePoint\Updates"
    $march2013PUTempFolder = "$Destination\SharePoint\Updates\March2013PU_TEMP"
    # Remove any existing .xml or .msp files
    foreach ($existingItem in (Get-ChildItem -Path $march2013PUTempFolder -ErrorAction SilentlyContinue))
    {
        $existingItem | Remove-Item -Force -Confirm:$false
    }
    # Extract SharePoint PU files to $march2013PUTempFolder
    Write-Host " - Extracting $($march2013PU.Name) Public Update patch files..." -NoNewline
    Start-Process -FilePath "$UpdateLocation\$updateSubfolder\$($march2013PU.ExpandedFile)" -ArgumentList "/extract:`"$march2013PUTempFolder`" /passive" -Wait -NoNewWindow
    Read-Log
    Write-Host "done!"
    # Now that we have a supported way to slispstream BOTH the March 2013 PU as well as a subsequent CU (per http://blogs.technet.com/b/acasilla/archive/2014/03/09/slipstream-sharepoint-2013-with-march-pu-cu.aspx), let's make it happen.
    Write-Host " - Processing $($march2013PU.Name) Public Update patch files (to allow slipstreaming with a later CU)..." -NoNewline
    # Grab every file except for the eula.txt (or any other text files) and any pre-existing renamed files
    foreach ($item in (Get-ChildItem -Path "$march2013PUTempFolder" | Where-Object {$_.Name -notlike "*.txt" -and $_.Name -notlike "_*SP0"}))
    {
        $prefix,$extension = $item -split "\."
        $newName = "_$prefix-SP0.$extension"
        if (Test-Path -Path "$march2013PUTempFolder\$newName")
        {
            Remove-Item -Path "$march2013PUTempFolder\$newName" -Force -Confirm:$false
        }
        Rename-Item -Path "$($item.FullName)" -NewName $newName -ErrorAction Inquire
    }
    # Move March 2013 PU files up into \Updates folder
    foreach ($item in (Get-ChildItem -Path "$march2013PUTempFolder"))
    {
        $item | Move-Item -Destination "$Destination\SharePoint\Updates" -Force
    }
    Remove-Item -Path $march2013PUTempFolder -Force -Confirm:$false
    Write-Host "done!"    
    WriteLine
}
#endregion

#region Download & slipstream SharePoint CU(s)
If ($spCU.Count -ge 1)
{
    $null,$null,[int]$spServicePackBuildNumber,$null = $spServicePack.Build -split "\."
    $null,$null,[int]$spCUBuildNumber,$null = $spCUBuild -split "\."
    if (($spCU.Url[0] -like "*`/$($spServicePack.Name)`/*") -and ($spServicePackBuildNumber -gt $spCUBuildNumber)) # New; only get the CU if its URL doesn't contain the service pack we already have and if the build is older, as it will likely be older
    {
        Write-Host -ForegroundColor DarkGray " - The $($spCU.Name[0]) update appears to be older than the SharePoint $spYear service pack or binaries, skipping."
        # Mark that the CU, although requested, has been skipped for the reason above. Used so that the output .txt file report remains accurate.
        $spCUSkipped = $true
    }
    else
    {
        WriteLine
        foreach ($spCUpackage in $spCU)
        {
            $spCUPackageName = $spCUpackage.Name
            $spCUPackageBuild = $spCUpackage.Build
            $spCUFile = $($spCUPackage.Url).Split('/')[-1]
            Write-Host " - Getting SharePoint $spYear $($spCUPackageName) update file ($spCUFile):"
            if ($spCUPackage.Url -like "*zip.exe")
            {
                $spCuFileIsZip = $true
                $spCuFile += ".zip"
            }
            # Set the subfolder name for easy update build & name identification, for example, "15.0.4481.1005 (March 2013)"
            $updateSubfolder = $spCUPackageBuild+" ("+$spCUPackageName+")"
            EnsureFolder "$UpdateLocation\$updateSubfolder"
            ##Write-Host " - Downloading $spCuFile to `"$UpdateLocation\$updateSubfolder`" using $($spCUPackage.Url) and expanding to $($spCUPackage.ExpandedFile)"
            DownloadPackage -Url $($spCUPackage.Url) -ExpandedFile $($spCUPackage.ExpandedFile) -DestinationFolder "$UpdateLocation\$updateSubfolder" -destinationFile $spCuFile
            # Expand CU executable to $UpdateLocation\$updateSubfolder
            If (!(Test-Path "$UpdateLocation\$updateSubfolder\$($spCUPackage.ExpandedFile)") -and $spCuFileIsZip) # Ensure the expanded file isn't already there, and the CU is a zip
            {
                $spCuFileZipPath = Join-Path -Path "$UpdateLocation\$updateSubfolder" -ChildPath $spCuFile
                Write-Host " - Expanding $spCuFile $(if ($spYear -eq "2016") {"Public"} else {"Cumulative"}) Update (single file)..."
                # Remove any pre-existing hotfix.txt file so we aren't prompted to replace it by Expand-Zip and cause our script to pause
                if (Test-Path -Path "$UpdateLocation\$updateSubfolder\hotfix.txt" -ErrorAction SilentlyContinue)
                {
                    Remove-Item -Path "$UpdateLocation\$updateSubfolder\hotfix.txt" -Confirm:$false -ErrorAction SilentlyContinue
                }
                Expand-Zip -InputFile $spCuFileZipPath -DestinationFolder "$UpdateLocation\$updateSubfolder"
            }
            Remove-ReadOnlyAttribute -Path "$Destination\SharePoint\Updates"
            # Extract SharePoint CU files to $Destination\SharePoint\Updates (but only if the source file is an .exe)
            if ($spCUPackage.ExpandedFile -like "*.exe")
            {
                # Assuming this is the the "launcher" package and the only one with an .exe extension. This is to differentiate from the ubersrv*.cab files included recently as part of CUs
                [array]$spCULaunchers += $spCUPackage.ExpandedFile
            }
        }
        if ($spCULaunchers) # Now that all packages have been downloaded we can call the launcher .exe to extract the CU
        {
            Write-Host -ForegroundColor Cyan " - NOTE: Recent updates can take a VERY long time to extract, so please be patient!"
            Write-Host " - Extracting $($spCUName) $(if ($spYear -eq "2016") {"Public"} else {"Cumulative"}) Update patch files..."
            foreach ($spCULauncher in $spCULaunchers)
            {
                Write-Host "  - $spCULauncher..." -NoNewline
                Start-Process -FilePath "$UpdateLocation\$updateSubfolder\$spCULauncher" -ArgumentList "/extract:`"$Destination\SharePoint\Updates`" /passive" -Wait -NoNewWindow
                Write-Host "done!"
                Read-Log
            }
            Write-Host " - Extracting update patch files done!"
        }
        WriteLine
    }
}
#endregion

#region Office Web Apps / Online Server
if ($WACSourceLocation)
{
    if ($spYear -le 2013) {$wacProductName = "Office Web Apps"; $wacNodeName = "OfficeWebApps"}
    elseif ($spYear -ge 2016) {$wacProductName = "Office Online Server"; $wacNodeName = "OfficeOnlineServer"}
    $wacNode = $xml.Products.Product | Where-Object {$_.Name -eq "$wacNodeName$spYear"}
    $wacServicePack = $wacNode.ServicePacks.ServicePack | Where-Object {$_.Name -eq $spServicePack.Name} # To match the chosen SharePoint service pack
    if ($wacServicePack.Name -eq "SP1" -and $spYear -eq "2010") {$wacMspCount = 16}
    if ($wacServicePack.Name -eq "SP2" -and $spYear -eq "2010") {$wacMspCount = 32}
    else {$wacMspCount = 0}
    # Create a hash table with some directories to look for to confirm the valid presence of the WAC binaries. Not perfect.
    $wacTestDirs = @{"2010" = "XLSERVERWAC.en-us"; "2013" = "wacservermui.en-us"; "2016" = "wacserver.ww"}
    ##if ($spYear -eq "2010") {$wacTestDir = "XLSERVERWAC.en-us"}
    ##elseif ($spYear -eq "2013") {$wacTestDir = "wacservermui.en-us"}
    # Try to find a OWA/OOS update that matches the current month for the SharePoint update
    [array]$wacCU = $wacNode.CumulativeUpdates.CumulativeUpdate | Where-Object {$_.Name -eq $spCUName}
    [array]$wacCUNodes = $wacNode.CumulativeUpdates.ChildNodes | Where-Object {$_.NodeType -ne "Comment"}
    if ([string]::IsNullOrEmpty($wacCU))
    {
        Write-Host " - There is no $($spCUName) update for $wacProductName available."
        while ([string]::IsNullOrEmpty($wacCUName) -and (($wacCUNodes).Count -ge 1))
        {
            Write-Host " - Please select another available $wacProductName update..."
            Start-Sleep 2
            $wacCUName =  $wacNode.CumulativeUpdates.CumulativeUpdate.Name | Select-Object -Unique | Out-GridView -Title "Please select another available $wacProductName update:" -PassThru
            if ($wacCUName.Count -gt 1) {Write-Warning "Please only select ONE update."; Remove-Variable -Name wacCUName -Force}
        }
        [array]$wacCU = $wacNode.CumulativeUpdates.CumulativeUpdate | Where-Object {$_.Name -eq $wacCUName}
    }
    else
    {
        Write-Host " - $($wacCU[0].Name) update found for $wacProductName."
    }
    if ($wacCU.Count -ge 1)
    {
        $wacCUName = $wacCU[0].Name
        $wacCUBuild = $wacCU[0].Build
    }
    WriteLine
    # Download Office Web Apps / Online Server?

    # Download Office Web Apps / Online Server 2013 Prerequisites
    If ($GetPrerequisites -and $spYear -ge 2013)
    {
        WriteLine
        $wacPrerequisiteNode = $wacNode.Prerequisites
        New-Item -ItemType Directory -Name "PrerequisiteInstallerFiles" -Path "$Destination\$wacNodeName" -ErrorAction SilentlyContinue | Out-Null
        foreach ($prerequisite in $wacPrerequisiteNode.Prerequisite)
        {
            Write-Host " - Getting $wacProductName prerequisite `"$($prerequisite.Name)`"..."
            DownloadPackage -Url $($prerequisite.Url) -DestinationFolder "$Destination\$wacNodeName\PrerequisiteInstallerFiles"
        }
        WriteLine
    }

    # Extract Office Web Apps / Online Server files to $Destination\$wacNodeName
    $sourceDirWAC = $WACSourceLocation.TrimEnd("\")
    Write-Host " - Checking for $sourceDirWAC\$($wacTestDirs.$spYear)\..."
    $sourceFoundWAC = (Test-Path -Path "$sourceDirWAC\$($wacTestDirs.$spYear)" -ErrorAction SilentlyContinue)
    if (!$sourceFoundWAC)
    {
        Write-Warning " - The correct $wacProductName source files/media were not found!"
        Write-Warning " - Please specify a valid path."
        $errorWarning = $true
        break
        Pause "exit"
        exit
    }
    else
    {
        Write-Host " - Source found in $sourceDirWAC."
    }
    if (!($sourceDirWAC -eq "$Destination\$wacNodeName"))
    {
        Write-Host " - (Robo-)copying files from $sourceDirWAC to $Destination\$wacNodeName..."
        Start-Process -FilePath robocopy.exe -ArgumentList "`"$sourceDirWAC`" `"$Destination\$wacNodeName`" /E /Z /ETA /NDL /NFL /NJH /XO /A-:R" -Wait -NoNewWindow
        Write-Host " - Done copying original files to $Destination\$wacNodeName."
    }

    if (!([string]::IsNullOrEmpty($wacServicePack.Name)))
    {
        # Check if WAC SP already appears to be included in the source
        if ((Get-ChildItem "$sourceDirWAC\Updates" -Filter *.msp).Count -lt $wacMspCount) # Checking for ($wacMspCount) MSP patch files in the \Updates folder
        {
            Write-Host " - WAC $($wacServicePack.Name) seems to be missing or incomplete in $sourceDirWAC; downloading..."
            # Download Office Web Apps / Online Server service pack
            Write-Host " - Getting $wacProductName $($wacServicePack.Name):"
            # Set the subfolder name for easy update build & name identification, for example, "15.0.4481.1005 (March 2013)"
            $wacServicePackSubfolder = $wacServicePack.Build+" ("+$wacServicePack.Name+")"
            EnsureFolder "$UpdateLocation\$wacServicePackSubfolder"
            DownloadPackage -Url $($wacServicePack.Url) -DestinationFolder "$UpdateLocation\$wacServicePackSubfolder"
            Remove-ReadOnlyAttribute -Path "$Destination\$wacNodeName\Updates"
            # Extract Office Web Apps / Online Server service pack files to $Destination\$wacNodeName\Updates
            Write-Host " - Extracting $wacProductName $($wacServicePack.Name) patch files..." -NoNewline
            $wacServicePackExpandedFile = $($wacServicePack.Url).Split('/')[-1]
            Start-Process -FilePath "$UpdateLocation\$wacServicePackSubfolder\$wacServicePackExpandedFile" -ArgumentList "/extract:`"$Destination\$wacNodeName\Updates`" /passive" -Wait -NoNewWindow
            Read-Log
            Write-Host "done!"
        }
        else {Write-Host " - WAC $($wacServicePack.Name) appears to be already slipstreamed into the SharePoint binary source location."}
    }
    else {Write-Host " - No WAC service packs are available or applicable for this version."}

    if ($spCU.Count -ge 1 -and [string]::IsNullOrEmpty($wacCU))
    {
    }
    if (!([string]::IsNullOrEmpty($wacCU))) # Only attempt this if we actually have a CU for WAC that matches the SP revision
    {
        # Download Office Web Apps / Online Server CU
        foreach ($wacCUPackage in $wacCU)
        {
            Write-Host " - Getting $wacProductName $wacCUName update:"
            $wacCuFileZip = $($wacCUPackage.Url).Split('/')[-1] +".zip"
            # Set the subfolder name for easy update build & name identification, for example, "15.0.4481.1005 (March 2013)"
            $wacUpdateSubfolder = $wacCUBuild+" ("+$wacCUName+")"
            EnsureFolder "$UpdateLocation\$wacUpdateSubfolder"
            DownloadPackage -Url $($wacCUPackage.Url) -ExpandedFile $($wacCUPackage.ExpandedFile) -DestinationFolder "$UpdateLocation\$wacUpdateSubfolder" -destinationFile $wacCuFileZip

            # Expand Office Web Apps / Online Server CU executable to $UpdateLocation\$wacUpdateSubfolder
            If (!(Test-Path "$UpdateLocation\$wacUpdateSubfolder\$($wacCUPackage.ExpandedFile)")) # Check if the expanded file is already there
            {
                $wacCuFileZipPath = Join-Path -Path "$UpdateLocation\$wacUpdateSubfolder" -ChildPath $wacCuFileZip
                Write-Host " - Expanding $wacProductName $(if ($spYear -eq "2016") {"Public"} else {"Cumulative"}) Update (single file)..."
                EnsureFolder "$UpdateLocation\$wacUpdateSubfolder"
                # Remove any pre-existing hotfix.txt file so we aren't prompted to replace it by Expand-Zip and cause our script to pause
                if (Test-Path -Path "$UpdateLocation\$wacUpdateSubfolder\hotfix.txt" -ErrorAction SilentlyContinue)
                {
                    Remove-Item -Path "$UpdateLocation\$wacUpdateSubfolder\hotfix.txt" -Confirm:$false -ErrorAction SilentlyContinue
                }
                Expand-Zip -InputFile $wacCuFileZipPath -DestinationFolder "$UpdateLocation\$wacUpdateSubfolder"
            }
            Remove-ReadOnlyAttribute -Path "$Destination\$wacNodeName\Updates"
            # Extract Office Web Apps / Online Server CU files to $Destination\$wacNodeName\Updates
            Write-Host " - Extracting $wacProductName $(if ($spYear -eq "2016") {"Public"} else {"Cumulative"}) Update patch files..." -NoNewline
            Start-Process -FilePath "$UpdateLocation\$wacUpdateSubfolder\$($wacCUPackage.ExpandedFile)" -ArgumentList "/extract:`"$Destination\$wacNodeName\Updates`" /passive" -Wait -NoNewWindow
            Write-Host "done!"
        }
    }
    else {Write-Host " - No $wacProductName updates are available or applicable for this version."}
    WriteLine
}
#endregion

#region Download & slipstream Language Packs
If ($Languages.Count -gt 0)
{
    $lpNode = $spNode.LanguagePacks
    ForEach ($language in $Languages)
    {
        WriteLine
        $spLanguagePack = $lpNode.LanguagePack | Where-Object {$_.Name -eq $language}
        If (!$spLanguagePack)
        {
            Write-Warning " - Language Pack `"$language`" invalid, or not found - skipping."
        }
        if ([string]::IsNullOrEmpty($spLanguagePack.Url))
        {
            Write-Warning " - There is no download URL for Language Pack `"$language`" yet - skipping. You may need to download it manually from MSDN/Technet."
        }
        Else
        {
            # Download the language pack
            [array]$validLanguages += $language
            $lpDestinationFile = $($spLanguagePack.Url).Split('/')[-1]
            # Give it a more descriptive name if the language sub-string is not already present
            if (!($lpDestinationFile -like "*$language*"))
            {
                if ($spver -eq "14")
                {
                    $lpDestinationFile = $lpDestinationFile -replace ".exe","_$language.exe"
                }
                else
                {
                    $lpDestinationFile = $lpDestinationFile -replace ".img","_$language.img"
                }
            }
            Write-Host " - Getting SharePoint $spYear Language Pack ($language):"
            # Set the subfolder name for easy update build & name identification, for example, "15.0.4481.1005 (March 2013)"
            $spLanguagePackSubfolder = $spLanguagePack.Name
            EnsureFolder "$UpdateLocation\$spLanguagePackSubfolder"
            DownloadPackage -Url $($spLanguagePack.Url) -DestinationFolder "$UpdateLocation\$spLanguagePackSubfolder" -DestinationFile $lpDestinationFile
            Remove-ReadOnlyAttribute -Path "$Destination\LanguagePacks\$language"
            # Extract the language pack to $Destination\LanguagePacks\xx-xx (where xx-xx is the culture ID of the language pack, for example fr-fr)
            if ($lpDestinationFile -match ".img$" -or $lpDestinationFile -match ".iso$")
            {
                # Mount the ISO/IMG file ($UpdateLocation\$spLanguagePackSubfolder\$lpDestinationFile) and robo-copy the files to $Destination\LanguagePacks\$language
                Write-Host " - Mounting language pack disk image..." -NoNewline
                Mount-DiskImage -ImagePath "$UpdateLocation\$spLanguagePackSubfolder\$lpDestinationFile" -StorageType ISO
                $isoDrive = (Get-DiskImage -ImagePath "$UpdateLocation\$spLanguagePackSubfolder\$lpDestinationFile" | Get-Volume).DriveLetter + ":"
                Write-Host "Done."

                # Copy files
                Write-Host " - (Robo-)copying language pack files from $isoDrive to $Destination\LanguagePacks\$language"
                Start-Process -FilePath robocopy.exe -ArgumentList "`"$isoDrive`" `"$Destination\LanguagePacks\$language`" /E /Z /ETA /NDL /NFL /NJH /XO /A-:R" -Wait -NoNewWindow
                Write-Host " - Done copying language pack files to $Destination\LanguagePacks\$language."
                # Dismount the ISO/IMG
                Dismount-DiskImage -ImagePath "$UpdateLocation\$spLanguagePackSubfolder\$lpDestinationFile"
            }
            else
            {
                Write-Host " - Extracting Language Pack files ($language)..." -NoNewline
                Start-Process -FilePath "$UpdateLocation\$spLanguagePackSubfolder\$lpDestinationFile" -ArgumentList "/extract:`"$Destination\LanguagePacks\$language`" /quiet" -Wait -NoNewWindow
                Write-Host "done!"
            }
            [array]$lpSpNodes = $splanguagePack.ServicePacks.ChildNodes | Where-Object {$_.NodeType -ne "Comment"}
            if (($lpSpNodes).Count -ge 1 -and $spServicePack)
            {
                # Download service pack for the language pack
                $lpServicePack = $spLanguagePack.ServicePacks.ServicePack | Where-Object {$_.Name -eq $spServicePack.Name} # To match the chosen SharePoint service pack
                $lpServicePackDestinationFile = $($lpServicePack.Url).Split('/')[-1]
                Write-Host " - Getting SharePoint $spYear Language Pack $($lpServicePack.Name) ($language):"
                EnsureFolder "$UpdateLocation\$spLanguagePackSubfolder"
                DownloadPackage -Url $($lpServicePack.Url) -DestinationFolder "$UpdateLocation\$spLanguagePackSubfolder" -DestinationFile $lpServicePackDestinationFile
                if (Test-Path -Path "$Destination\LanguagePacks\$language\Updates") {Remove-ReadOnlyAttribute -Path "$Destination\LanguagePacks\$language\Updates"}
                # Extract each language pack to $Destination\LanguagePacks\xx-xx (where xx-xx is the culture ID of the language pack, for example fr-fr)
                if ($lpServicePackDestinationFile -match ".img$")
                {
                    # Mount the ISO/IMG file ($UpdateLocation\$spLanguagePackSubfolder\$lpDestinationFile) and robo-copy the files to $Destination\LanguagePacks\$language
                    Write-Host " - Mounting language pack service pack disk image..." -NoNewline
                    Mount-DiskImage -ImagePath "$UpdateLocation\$spLanguagePackSubfolder\$lpServicePackDestinationFile" -StorageType ISO
                    $isoDrive = (Get-DiskImage -ImagePath "$UpdateLocation\$spLanguagePackSubfolder\$lpServicePackDestinationFile" | Get-Volume).DriveLetter + ":"
                    Write-Host "Done."

                    # Copy files
                    Write-Host " - (Robo-)copying language pack service pack files from $isoDrive to $Destination\LanguagePacks\$language"
                    Start-Process -FilePath robocopy.exe -ArgumentList "`"$isoDrive`" `"$Destination\LanguagePacks\$language`" /E /Z /ETA /NDL /NFL /NJH /XO /A-:R" -Wait -NoNewWindow
                    Write-Host " - Done copying language pack service pack files to $Destination\LanguagePacks\$language."
                    # Dismount the ISO/IMG
                    Dismount-DiskImage -ImagePath "$UpdateLocation\$spLanguagePackSubfolder\$lpServicePackDestinationFile"
                }
                else
                {
                    Write-Host " - Extracting Language Pack $($lpServicePack.Name) files ($language)..." -NoNewline
                    Start-Process -FilePath "$UpdateLocation\$spLanguagePackSubfolder\$lpServicePackDestinationFile" -ArgumentList "/extract:`"$Destination\LanguagePacks\$language\Updates`" /quiet" -Wait -NoNewWindow
                    Write-Host "done!"
                }
            }
        }
        If ($spCU.Count -ge 1 -and (Test-Path -Path "$Destination\LanguagePacks\$language\Updates"))
        {
            # Copy matching culture files from $Destination\SharePoint\Updates folder (e.g. spsmui-fr-fr.msp) to $Destination\LanguagePacks\$language\Updates
            Write-Host " - Updating $Destination\LanguagePacks\$language with the $($spCUName) SharePoint update..."
            ForEach ($patch in (Get-ChildItem -Path $Destination\SharePoint\Updates -Filter *$language*))
            {
                Copy-Item -Path $patch.FullName -Destination "$Destination\LanguagePacks\$language\Updates" -Force
            }
        }
        WriteLine
    }
}
#endregion

#region Create labeled ISO?
#WriteLine
#WriteLine
#endregion

#region Wrap Up
WriteLine
Write-Host " - Adding a label file `"_SLIPSTREAMED.txt`"..."
Set-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value "This media source directory has been slipstreamed with:" -Force
Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value `n -Force
Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value "- SharePoint $spYear" -Force
If (!([string]::IsNullOrEmpty($spServicePack)))
{
    Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value " - $($spServicePack.Name) for SharePoint $spYear" -Force
}
If (!([string]::IsNullOrEmpty($march2013PU)))
{
    Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value " - $($march2013PU.Name) Public Update for SharePoint $spYear" -Force
}
If (($spCU.Count -ge 1) -and !$spCUSkipped)
{
    Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value " - $($spCUName) $(if ($spYear -eq "2016") {"Public"} else {"Cumulative"}) Update for SharePoint $spYear" -Force
}
If ($GetPrerequisites)
{
    Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value " - Prerequisite software for SharePoint $spYear" -Force
}
if ($patchedForKB3087184)
{
    Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value " - .Net Framework 4.6 installation compatibility update (KB3087184) for SharePoint $spYear" -Force
}
If ($validLanguages.Count -gt 0) # Add the language packs to the txt file only if they were actually valid
{
    Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value "- Language Packs:" -Force
    ForEach ($language in $validLanguages)
    {
        Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value " - $language" -Force
    }
}
If (!([string]::IsNullOrEmpty($WACSourceLocation)))
{
    Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value "- $wacProductName $spYear" -Force
    if (!([string]::IsNullOrEmpty($wacPrerequisiteNode)))
    {
        Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value " - Prerequisite software for $wacProductName $spYear" -Force
    }
    if (!([string]::IsNullOrEmpty($wacServicePack)))
    {
        Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value " - $($wacServicePack.Name) for $wacProductName $spYear" -Force
    }
    if (!([string]::IsNullOrEmpty($wacCU)))
    {
        Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value " - $($wacCUName) $(if ($spYear -eq "2016") {"Public"} else {"Cumulative"}) Update for $wacProductName $spYear" -Force
    }
}
Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value `n -Force
Add-Content -Path "$Destination\_SLIPSTREAMED.txt" -Value "Using AutoSPSourceBuilder (https://github.com/brianlala/autospsourcebuilder)." -Force
If ($errorWarning)
{
    Write-Host -ForegroundColor Yellow " - At least one non-trivial error was encountered."
    Write-Host -ForegroundColor Yellow " - Your SharePoint installation source could therefore be incomplete."
    Write-Host -ForegroundColor Yellow " - You should re-run this script until there are no more errors."
}
Write-Host " - Done!"
Write-Host " - Review the output and check your source location integrity carefully."
Start-Sleep -Seconds 5
<#
Invoke-Item -Path $Destination
WriteLine
$Host.UI.RawUI.WindowTitle = $oldTitle
Pause "exit"
#>
#endregion