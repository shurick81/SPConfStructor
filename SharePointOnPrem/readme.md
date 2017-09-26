# DSC scripts for provisioning SharePoint development environment in Azure

Advantages:
* Saves your time with fully automated development environment configuration.
* Improves development quality by controlling the development environment as a code.
* Single source of configuration for Azure virtual machines and SharePoint.
* Automated compiling DSC-files for non-azure environment (production, UAT, etc.).


Shortest path to the stuff:

1. Make sure you have AzureRM.Compute PowerShell module 3.3.1 or higher on your machine.
2. Copy all the files on your machine.
3. Run "azureDeploy.ps1".
4. Authenticate.
5. Wait until the script finishes and connects you to the new machines via RDP.


