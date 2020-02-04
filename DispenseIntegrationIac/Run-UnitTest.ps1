Param(
    [string] [Parameter(Mandatory=$true)] $TestFilePath,
    [string] [Parameter(Mandatory=$true)] $OutputDirectory,
    [string] [Parameter(Mandatory=$true)] $BuildNumber,
	[string] [Parameter(Mandatory=$true)] $TemplateFile,
	[string] [Parameter(Mandatory=$true)] $TemplateParametersFile
)

$segment = $TestFilePath.Split("\")
$testFile = $segment[$segment.Length - 1].Replace(".ps1", "");
$outputFile = "$OutputDirectory\TEST-$testFile-$BuildNumber.xml"
$parameters = @{ TemplateFile = $TemplateFile; TemplateParametersFile = $TemplateParametersFile }

$script = @{ Path = $TestFilePath ; Parameters = $parameters }

Invoke-Pester -Script $script -OutputFile $outputFile -OutputFormat NUnitXml
