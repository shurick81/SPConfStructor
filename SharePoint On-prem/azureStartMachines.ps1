$configParameters = Import-PowershellDataFile mainParemeters.psd1;
$configParameters.Machines | ? { $_.Roles -contains "AD" } | % {
    Start-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name;
}
$configParameters.Machines | ? { $_.Roles -notcontains "AD" } | % {
    Start-AzureRmVM -ResourceGroupName $azureParameters.ResourceGroupName -Name $_.Name;
}