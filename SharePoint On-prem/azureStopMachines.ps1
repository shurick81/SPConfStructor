$configParameters = Import-PowershellDataFile mainParemeters.psd1;
$configParameters.Machines | ? { $_.Roles -notcontains "AD" } | % {
    Stop-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name -Force;
}
$configParameters.Machines | ? { $_.Roles -contains "AD" } | % {
    Stop-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name -Force;
}
