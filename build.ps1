[cmdletbinding()]
param(
    [string[]]$Task = 'default'
)


Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Install-Module Psake, PSDeploy, PSScriptAnalyzer -force
Install-Module Pester -Force -SkipPublisherCheck 
Import-Module Psake, Pester, PSScriptAnalyzer

try {
    Invoke-psake -buildFile "$PSScriptRoot\psake.ps1" -taskList $Task -Verbose:$VerbosePreference -ErrorAction Stop
}
catch {
    exit 1
}

