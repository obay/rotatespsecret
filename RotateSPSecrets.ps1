param (
    [Parameter(Mandatory = $true)]
    [string] $subscriptionName,

    [Parameter(Mandatory = $true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $tenantId,

    [Parameter(Mandatory = $true)]
    [string] $spName,

    [Parameter(Mandatory = $true)]
    [string] $spPassword
)

# Set the subscription context ####################################################################
$securePassword = ConvertTo-SecureString -String $spPassword -AsPlainText -Force
$credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $spName, $securePassword

Connect-AzAccount -ServicePrincipal -TenantId $tenantId -Credential $credential

Select-AzSubscription -Subscription $subscriptionName
# Get all Key Vaults in the specified resource group ##############################################
$keyVaults = Get-AzKeyVault -ResourceGroupName $resourceGroupName

foreach ($keyVault in $keyVaults) {
    # Get the key vault name
    $keyVaultName = $keyVault.VaultName
    # Grant myself access to the Key Vault to Get, List and Set secrets ###########################
    Write-Output "Granting access to Key Vault: $keyVaultName"

    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ResourceGroupName $resourceGroupName -PermissionsToSecrets Get, List, Set -ServicePrincipalName $spName
    Write-Output "Access granted to Key Vault: $keyVaultName"
    # Check if the Key Vault contains the secret named 'ccid' #####################################
    try {
        $ccidSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "ccid"
        if ($ccidSecret) {
            $clientId = ConvertFrom-SecureString -SecureString $ccidSecret.SecretValue -AsPlainText
            $servicePrincipal = Get-AzADServicePrincipal -Filter "appId eq '$clientId'"
            
            if ($servicePrincipal) {
                # Delete all existing password credentials for the service principal
                Remove-AzADSpCredential -ObjectId $servicePrincipal.Id
                
                # Generate a new password for the service principal that expires in 7 days
                $newClientSecret = New-AzADSpCredential -ObjectId $servicePrincipal.Id -EndDate (Get-Date).AddDays(7)
                
                # Store the new password in the Key Vault under the key 'secret'
                Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "secret" -SecretValue (ConvertTo-SecureString -String $newClientSecret.SecretText -AsPlainText -Force)

                Write-Output "Updated secret for Key Vault: $keyVaultName"
            }
        }
    }
    catch {
        Write-Output "Secret 'ccid' not found in Key Vault: $keyVaultName"
    }
}

Write-Output "Script execution completed."
