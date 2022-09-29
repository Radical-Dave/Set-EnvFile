Describe 'file tests' {
    BeforeAll {
        $ModuleScriptPath = $PSCommandPath.Replace('\tests\','\').Replace('.File.Tests.','.')
        Write-Host "ModuleScriptPath=$ModuleScriptPath"
        $ModuleScriptPath | Should -Not -BeNullOrEmpty
        $PSScriptName = (Split-Path $ModuleScriptPath -Leaf).Replace('.ps1','')
        Write-Host "PSScriptName=$PSScriptName"
        $PSScriptName | Should -Not -BeNullOrEmpty
        . $ModuleScriptPath
    }
    It 'passes default PSScriptAnalyzer rules' {        
       Invoke-ScriptAnalyzer -Path $ModuleScriptPath | Should -Not -BeNullOrEmpty
    }
    It 'passes empty params' {
        $results = {&"$PSScriptName -verbose"} | Should -Not -BeNullOrEmpty
        Write-Host "results=$results"
    }
    It 'passes do test' {
        #$results = . .\"$PSScriptName"
        $results = {&"$PSScriptName -verbose"} | Should -Not -BeNullOrEmpty
        Write-Host "results=$results"
        $results | Should -Not -BeNullOrEmpty
        $check = [System.Environment]::GetEnvironmentVariable('subscription')
        $check | Should -Not -BeNullOrEmpty        
    }
}