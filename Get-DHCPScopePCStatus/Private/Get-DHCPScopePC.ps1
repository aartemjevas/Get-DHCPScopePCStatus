Function Get-DHCPScopePC {
    [CmdletBinding()]
    param(  [Parameter(Mandatory=$true)]
            [string]$ScopeID,
            [Parameter(Mandatory=$true)]
            [string]$Server
    )
    try {
        Get-DhcpServerv4Lease -ComputerName $Server -ScopeId $ScopeID -ErrorAction Stop |
            Select @{Label='IPAddress';Expression={$_.IPAddress.IPAddressToString}},
                    ClientId, HostName
    } 
    catch {
        throw $_.exception.message
    }
    
}
