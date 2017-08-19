$azureParameters = Import-PowershellDataFile azureParameters.psd1;
Remove-AzureRmResourceGroup -Name $azureParameters.ResourceGroupName -Force | Out-Null;
