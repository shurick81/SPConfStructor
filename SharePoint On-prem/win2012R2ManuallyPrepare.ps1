#manual preparation of Win2012R2 machines to run mof files

$url = "http://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu"
$installerFolder = "C:\Install\WMF5.1"
if ( !( Test-Path -path $installerFolder ) )
{
    New-Item -ItemType directory -Path $installerFolder | Out-Null
}
Import-Module BitsTransfer
Start-BitsTransfer -Source $url -Destination "$installerFolder\Win8.1AndW2K12R2-KB3191564-x64.msu" | Out-Null

wusa.exe "$installerFolder\Win8.1AndW2K12R2-KB3191564-x64.msu" /quiet


#For installing SQL:

$url = "http://download.microsoft.com/download/4/3/F/43F0465E-45AC-4901-8CE2-7B4B94A70356/Windows8.1-KB2966828-x64.msu"
$installerFolder = "C:\Install\NETFramework35"
if ( !( Test-Path -path $installerFolder ) )
{
    New-Item -ItemType directory -Path $installerFolder | Out-Null
}
Import-Module BitsTransfer
Start-BitsTransfer -Source $url -Destination "$installerFolder\Windows8.1-KB2966828-x64.msu" | Out-Null

wusa.exe "$installerFolder\Windows8.1-KB2966828-x64.msu" /quiet
