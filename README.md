# Azure Service Principle Secret Key Rotation

This PowerShell script is created to rotate service principale secret keys in Azure.

## Prerequisites

- Azure PowerShell Module
- Azure Subscription with Key Vaults
- Service Principal with appropriate permissions

## Parameters

The script requires the following parameters:

- `subscriptionName` (string, mandatory): The name of the Azure subscription.
- `resourceGroupName` (string, mandatory): The name of the resource group containing the Key Vaults.
- `tenantId` (string, mandatory): The tenant ID of the Azure AD.
- `spName` (string, mandatory): The name (client ID) of the service principal.
- `spPassword` (string, mandatory): The password (client secret) of the service principal.

## Usage

Run the script with the required parameters. Example:

```powershell
.\RotateSPSecrets.ps1 -subscriptionName "YourSubscriptionName" -resourceGroupName "YourResourceGroupName" -tenantId "YourTenantId" -spName "YourServicePrincipalName" -spPassword "YourServicePrincipalPassword"
```
