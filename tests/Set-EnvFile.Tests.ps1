Describe 'smoke tests' {
    BeforeAll {
        $ModuleScriptPath = $PSCommandPath.Replace('\tests\','\').Replace('.Tests.','.')
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
        {&"$PSScriptName"} | Should -Not -BeNullOrEmpty
    }
    It 'passes do test' {
        $results = . .\"$PSScriptName"
        $results | Should -Not -BeNullOrEmpty
        $check = [System.Environment]::GetEnvironmentVariable('subscription')
        $check | Should -Not -BeNullOrEmpty        
    }
}