#Requires -Version 3.0
#Requires -Modules Pester

<#
.SYNOPSIS
    Tests a specific ARM template
.EXAMPLE
    Invoke-Pester 
.NOTES
    This file has been created as an example of using Pester to evaluate ARM templates
#>

Param(
  [string] [Parameter(Mandatory=$true)] $TemplateFile,
  [string] [Parameter(Mandatory=$true)] $TemplateParametersFile
)

$scriptPath = "$env:BUILD_SOURCESDIRECTORY\DispenseIntegrationIaC"
$templateFileLocation = "$scriptPath\$TemplateFile"
$templateParemeterFileLocation = "$scriptPath\$TemplateParametersFile" 


Describe 'ARM Templates Test : Validation & Test Deployment' {
    
    Context 'Template Validation' {
        
        It 'Has a JSON template' {        
            $templateFileLocation | Should Exist
        }
        
        It 'Has a parameters file' {        
            $templateParemeterFileLocation | Should Exist
        }
		
        

        It 'Converts from JSON and has the expected properties' {
            $expectedProperties = '$schema',
                                  'contentVersion',
                                  'parameters',
                                  'resources',                                
                                  'variables'
            $templateProperties = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | % Name
            $templateProperties | Should Be $expectedProperties
        }
    }
}
