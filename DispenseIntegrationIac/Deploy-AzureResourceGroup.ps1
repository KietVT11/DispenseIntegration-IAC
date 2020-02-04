Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$ScriptPath = Split-Path $MyInvocation.InvocationName

Write-Host "Script Path: $ScriptPath"

Invoke-Expression "& `"$ScriptPath\Set-Parameters.ps1`""

$ScriptArgument = '-SubscriptionName $subscriptionName -ResourceGroupName $resourceGroupName -ResourceGroupLocation $resourceGroupLocation'
Invoke-Expression "& `"$ScriptPath\scripts\Create-ResourceGroup.ps1`" $ScriptArgument"

$ScriptArgument = '-ResourceGroupName $resourceGroupName -ResourceGroupLocation $resourceGroupLocation'
Invoke-Expression "& `"$ScriptPath\scripts\Deploy-ResourceGroup.ps1`" $ScriptArgument"

$ScriptArgument = '-KeyVaultName $keyVaultName -ResourceGroupName $resourceGroupName -ResourceGroupLocation $resourceGroupLocation'
Invoke-Expression "& `"$ScriptPath\scripts\Create-KeyVault.ps1`" $ScriptArgument"

$ScriptArgument = '-KeyVaultName $keyVaultName -SecretName $sqlUserSecretName -SecretValue $sqlUserSecretValue'
Invoke-Expression "& `"$ScriptPath\scripts\Create-KeyVaultSecret.ps1`" $ScriptArgument"

$ScriptArgument = '-KeyVaultName $keyVaultName -SecretName $sqlPasswordSecretName -SecretValue $sqlPasswordSecretValue'
Invoke-Expression "& `"$ScriptPath\scripts\Create-KeyVaultSecret.ps1`" $ScriptArgument"

$ScriptArgument = '-ResourceGroupName $resourceGroupName -ResourceGroupLocation $resourceGroupLocation -KeyVaultName $keyVaultName -SqlUserSecretName $sqlUserSecretName -SqlPassSecretName $sqlPasswordSecretName'
Invoke-Expression "& `"$ScriptPath\scripts\Deploy-ResourceGroup.ps1`" $ScriptArgument"
