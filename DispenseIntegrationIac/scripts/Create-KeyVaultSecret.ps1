#Requires -Version 3.0

Param(
	[string] [Parameter(Mandatory=$true)] $KeyVaultName,
    [string] [Parameter(Mandatory=$true)] $SecretName,
    [string] [Parameter(Mandatory=$true)] $SecretValue
)

$KeyVaultSecretValue = ConvertTo-SecureString -String $SecretValue -AsPlainText -Force

Write-Host "Creating keyvault secret...";
Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -SecretValue $KeyVaultSecretValue
