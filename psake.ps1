Properties {
    $scripts = Get-ChildItem "$PSScriptRoot\Get-DHCPScopePCStatus" -Filter *.ps1 -Recurse
}
Task Default -Depends LintTests,UnitTests

Task LintTests {
    'Running PSScriptAnalyzer'
    $saResults = Invoke-ScriptAnalyzer -Path "$PSScriptRoot\Get-DHCPScopePCStatus" -Severity @('Error','Warning') -Verbose:$false
    if ($saResults) {
        $saResults | Format-Table  
        Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'        
    }
}
Task UnitTests  {
    $TestResults = Invoke-Pester -Path $PSScriptRoot\Tests\Unit.Tests.ps1 -PassThru -Verbose:$false
    if($TestResults.FailedCount -gt 0)
    {
        Write-Error "$($TestResults.FailedCount) tests failed"
    }
}
