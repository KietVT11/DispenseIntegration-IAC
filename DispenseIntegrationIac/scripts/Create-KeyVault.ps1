#Requires -Version 3.0

Param(
	[string] [Parameter(Mandatory=$True)] $ResourceGroupName,
	[string] [Parameter(Mandatory=$true)] $ResourceGroupLocation,
	[string] [Parameter(Mandatory=$true)] $KeyVaultName
)

### Create or check for existing Key Vault
if (!(Get-AzureRmKeyVault -VaultName $KeyVaultName ))
{
    Write-Host "Creating new keyvault $KeyVaultName in $ResourceGroupName in location $ResourceGroupLocation";
    New-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupName -Location $ResourceGroupLocation -EnabledForTemplateDeployment
	$context = Get-AzureRmContext -ErrorAction Continue
	$userName = $context.Account.Id
	Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -EmailAddress $userName -PermissionsToKeys create,import,delete,list -PermissionsToSecrets set,delete -PassThru
}
else
{
	Write-Host "Using existing keyvault $KeyVaultName";
	$context = Get-AzureRmContext -ErrorAction Continue
	$userName = $context.Account.Id
	Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -EmailAddress $userName -PermissionsToKeys create,import,delete,list -PermissionsToSecrets set,delete -PassThru
}
