[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=1)]
    [string]$mainParametersFileName = "mainParemeters.psd1",
	
    [Parameter(Mandatory=$False,Position=2)]
    [string]$azureParametersFileName = "azureParameters.psd1"
)

Get-Date
$configParameters = Import-PowershellDataFile $mainParametersFileName;
$azureParameters = Import-PowershellDataFile $azureParametersFileName;
$commonDictionary = Import-PowershellDataFile commonDictionary.psd1;

$vmName = "SP2013Ent01sq01"
$rgName = $azureParameters.ResourceGroupName
$location = $azureParameters.ResourceGroupLocation
$imageName = "Win2014SQL2014SP1Raw"

Set-AzureRmVm -ResourceGroupName $rgName -Name $vmName -Generalized
$vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $rgName
$image = New-AzureRmImageConfig -Location $location -SourceVirtualMachineId $vm.ID
New-AzureRmImage -Image $image -ImageName $imageName -ResourceGroupName $rgName
