#Requires -Version 3.0

Param(
	[string] [Parameter(Mandatory=$true)] $SubscriptionName,
	[string] [Parameter(Mandatory=$True)] $ResourceGroupName,
	[string] [Parameter(Mandatory=$true)] $ResourceGroupLocation
)



# sign in
Write-Host "Logging in...";
function Get-LoginSession () {
    $Error.Clear()

    #if context already exist
    $context = Get-AzureRmContext -ErrorAction Continue
	

    foreach ($eacherror in $Error) {
        if ($eacherror.Exception.ToString() -like "*Run Login-AzureRmAccount*") {
            $context = $null
        }
    }

    if (!$context.Account) {
        $context = $null
    }

    if (!$context) {
        Login-AzurermAccount
    }
    else {
        Write-Host
        $context

    }

    $Error.Clear();
}

 Get-LoginSession

# select subscription
Write-Host "Selecting subscription '$SubscriptionName'";
Select-AzureRmSubscription -SubscriptionName $SubscriptionName

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Creating resource group '$ResourceGroupName' in location '$ResourceGroupLocation'";
	New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force
}
else{
    Write-Host "Using existing resource group '$ResourceGroupName'";
}
