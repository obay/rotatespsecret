param (
    [Parameter(Mandatory = $true)]
    [string] $subscriptionName,

    [Parameter(Mandatory = $true)]
    [string] $resourceGroupName
)

# Set the subscription context
Select-AzSubscription -Subscription $subscriptionName
$tenantId = (Get-AzContext).Tenant.Id
$resource = "https://management.azure.com/"

# Get all Key Vaults in the specified resource group
$keyVaults = Get-AzKeyVault -ResourceGroupName $resourceGroupName

foreach ($keyVault in $keyVaults) {
    # Get the key vault name
    $keyVaultName = $keyVault.VaultName

    # Check if the Key Vault contains the secret named 'ccid'
    try {
        $ccidSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "ccid"
        $secretSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "secret"

        if ($ccidSecret -and $secretSecret) {
            $clientId = ConvertFrom-SecureString -SecureString $ccidSecret.SecretValue -AsPlainText
            $clientSecret = ConvertFrom-SecureString -SecureString $secretSecret.SecretValue -AsPlainText

            # write the values to the console
            # Write-Output "keyVaultName: $keyVaultName"
            # Write-Output "clientId: $clientId"
            # Write-Output "clientSecret: $clientSecret"

            # Test the credentials
            # Create the request body
            $body = @{
                grant_type    = "client_credentials"
                client_id     = $clientId
                client_secret = $clientSecret
                resource      = $resource
            }

            # Convert the request body to URL-encoded format
            $bodyString = [System.Web.HttpUtility]::UrlEncode($body)

            # Convert the hashtable to URL-encoded string manually if above method fails
            $bodyString = ($body.GetEnumerator() | ForEach-Object { "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))" }) -join "&"

            # Make the HTTP request
            try {
                $response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -ContentType "application/x-www-form-urlencoded" -Body $bodyString
                # Check if the response contains an access token
                if ($response.access_token) {
                    Write-Output "Successfully authenticated with the provided credentials for client ID: $clientId"
                }
                else {
                    Write-Error "Failed to authenticate with the provided credentials."
                }
            }
            catch {
                Write-Error "Failed to authenticate with the provided credentials."
            }
        }
    }
    catch {
        Write-Output "Secret 'ccid' not found in Key Vault: $keyVaultName"
    }
}
