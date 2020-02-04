#Requires -Version 3.0

Param(
	[string] [Parameter(Mandatory=$True)] $ResourceGroupName,
	[string] [Parameter(Mandatory=$true)] $ResourceGroupLocation,
	[string] [Parameter(Mandatory=$true)] $KeyVaultName,
	[string] [Parameter(Mandatory=$true)] $SqlUserSecretName,
	[string] [Parameter(Mandatory=$true)] $SqlPassSecretName,
    [string] $StorageAccountName,
    [string] $StorageContainerName = 'dispenseintegration-artifacts',
    [string] $ArtifactStagingDirectory = '..\nestedtemplates'
)

$OptionalParameters = New-Object -TypeName Hashtable
$ArtifactStagingDirectory  = Split-Path (Split-Path $script:MyInvocation.MyCommand.Path -Parent) -Parent

$TemplateFile = '..\dispenseintegration.json'
$StorageAccountName = 'dipenintedeploystag'
$TemplateParametersFile = '..\dispenseintegration.dev.parameters.json'
$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))

#Upload nested template to temporarily Azure blob storage
Write-Host "Uploading template to temporarily Azure storage...";
$ArtifactStagingDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $ArtifactStagingDirectory))

# Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
$JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
if (($JsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
    $JsonParameters = $JsonParameters.parameters
}
$ArtifactsLocationName = '_artifactsLocation'
$ArtifactsLocationSasTokenName = '_artifactsLocationSasToken'
$OptionalParameters[$ArtifactsLocationName] = $JsonParameters | Select -Expand $ArtifactsLocationName -ErrorAction Ignore | Select -Expand 'value' -ErrorAction Ignore
$OptionalParameters[$ArtifactsLocationSasTokenName] = $JsonParameters | Select -Expand $ArtifactsLocationSasTokenName -ErrorAction Ignore | Select -Expand 'value' -ErrorAction Ignore

if ($StorageAccountName -eq '') {
    $StorageAccountName = 'stage' + ((Get-AzureRmContext).Subscription.SubscriptionId).Replace('-', '').substring(0, 19)
}
$StorageAccount = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $StorageAccountName})

# Create the storage account if it doesn't already exist
if ($StorageAccount -eq $null) {
    $StorageResourceGroupName = $ResourceGroupName
    New-AzureRmResourceGroup -Location "$ResourceGroupLocation" -Name $StorageResourceGroupName -Force
    $StorageAccount = New-AzureRmStorageAccount -StorageAccountName $StorageAccountName -Type 'Standard_LRS' -ResourceGroupName $StorageResourceGroupName -Location $ResourceGroupLocation
}

# Generate the value for artifacts location if it is not provided in the parameter file
if ($OptionalParameters[$ArtifactsLocationName] -eq $null) {
    $OptionalParameters[$ArtifactsLocationName] = $StorageAccount.Context.BlobEndPoint + $StorageContainerName
}

# Copy files from the local storage staging location to the storage account container
New-AzureStorageContainer -Name $StorageContainerName -Context $StorageAccount.Context -ErrorAction SilentlyContinue *>&1
$ArtifactFilePaths = Get-ChildItem $ArtifactStagingDirectory -Recurse -File | ForEach-Object -Process {$_.FullName}
foreach ($SourcePath in $ArtifactFilePaths) {
    Set-AzureStorageBlobContent -File $SourcePath -Blob $SourcePath.Substring($ArtifactStagingDirectory.length + 1) `
        -Container $StorageContainerName -Context $StorageAccount.Context -Force
}

# Generate a 4 hour SAS token for the artifacts location if one was not provided in the parameters file
if ($OptionalParameters[$ArtifactsLocationSasTokenName] -eq $null) {
    $OptionalParameters[$ArtifactsLocationSasTokenName] = ConvertTo-SecureString -AsPlainText -Force `
        (New-AzureStorageContainerSASToken -Container $StorageContainerName -Context $StorageAccount.Context -Permission r -ExpiryTime (Get-Date).AddHours(4))
}

$KeyVaultNameParam = 'keyVaultName'
$SqlUserSecretNameParam = 'sqlUserSecretName'
$SqlPassSecretNameParam = 'sqlPassSecretName'


$OptionalParameters[$KeyVaultNameParam] = $KeyVaultName
$OptionalParameters[$SqlUserSecretNameParam] = $SqlUserSecretName
$OptionalParameters[$SqlPassSecretNameParam] = $SqlPassSecretName

Write-Host "Starting deployment...";
New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
                                       -ResourceGroupName $ResourceGroupName `
                                       -TemplateFile $TemplateFile `
                                       -TemplateParameterFile $TemplateParametersFile `
                                       @OptionalParameters `
                                       -Force -Verbose `
                                       -ErrorVariable ErrorMessages
if ($ErrorMessages) {
        Write-Host '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }

#Read Only User for Webstercare Azure SQL Server

$sqlPasswordEncode = ConvertTo-SecureString -String $sqlPasswordSecretValue -AsPlainText -Force
$sqlCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqlUserSecretValue, $sqlPasswordEncode

Write-Host "Delete the storage account after deployment...";
Remove-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName -Force
