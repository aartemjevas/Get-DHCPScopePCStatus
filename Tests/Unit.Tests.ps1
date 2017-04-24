$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

$scripts = Get-ChildItem -Path $moduleRoot -Filter "*.ps1" -Recurse

foreach($script in $scripts)
{
  . $script.fullname
}

Describe "Get-DHCPScopePCStatus" {
    $command = Get-Command Get-DHCPScopePCStatus

    Mock 'Get-DHCPScopePC' {
        $res = @() 
        $res += [pscustomobject]@{'IPAddress' = '127.0.0.1'; 
                                    'ClientId' = '72-62-7f-d6-48-2c'; 
                                    'HostName' = 'Somepc.domain.local'}
        $res += [pscustomobject]@{'IPAddress' = '10.10.10.10'; 
                                    'ClientId' = '72-62-7f-d6-48-2d'; 
                                    'HostName' = 'Someother.domain.local'}
        return $res  
    }

    $computers = Get-DHCPScopePCStatus -ScopeID '127.0.0.0' -Server '127.0.0.1'

    It "ScopeID parameter should be mandatory" {
        $command.Parameters.ScopeID.Attributes.mandatory | Should be $true
    }
    It "Online parameter should be switch" {
        $command.Parameters.Online.SwitchParameter | Should be $true
    }
    It "Offline parameter should be switch" {
         $command.Parameters.Offline.SwitchParameter | Should be $true
    }
    It "Should return 2 computers" {
        $computers.count | Should be 2
    }
    It "Should return 1 online computer" {
        ($computers | Where-Object {$_.status -eq 'Online'}).count | Should be 1
    }
    It "Should return 1 offline computer" {
        ($computers | Where-Object {$_.status -eq 'Offline'}).count | Should be 1
    }
    It "Should try to get DHCP server IP with Get-DhcpServerInDC command" {
        Mock 'Get-DhcpServerInDC' { return [pscustomobject]@{'IPAddress' = @{'IPAddressToString' = '127.0.0.0'}} }
        Get-DHCPScopePCStatus -ScopeID '127.0.0.0'
        Assert-MockCalled -CommandName 'Get-DhcpServerInDC' -Times 1
    }
}
