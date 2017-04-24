<#
.SYNOPSIS
Gets Computers status from DHCP scope

.DESCRIPTION
The Get-DHCPScopePCStatus function gets computers from specified DHCP scope and checks if computers in the scope is turned on or off.
It returns an object wiht parameters - IPAddress, Status, MACAddress, Computername


.PARAMETER ScopeID 
DHCP Scope ID


.EXAMPLE
Gets computers status from scope 10.102.32.0
Get-DHCPScopePCStatus -ScopeID 10.102.32.0


.NOTES
In order to get information, you have to have access to DHCP server and RSAT installed.
#>
Function Get-DHCPScopePCStatus 
{

    [CmdletBinding()]
    param(  [Parameter(Mandatory=$true)]
            [string]$ScopeID,
            [switch]$Online,
            [switch]$Offline,
            [string]$Server = $( try {(Get-DhcpServerInDC -ErrorAction stop | 
                                        Select-Object -First 1).IPAddress.IPAddressToString} catch {})
    )

    try
    {
        if ([string]::IsNullOrEmpty($Server)) {
            throw "Failed to get DHCP Servers IP Address"
            return
        }
        $DHCPLeases = Get-DHCPScopePC -Server $Server -ScopeId $ScopeID -ErrorAction Stop
        $count = 1
        $i = 0
        $groupMax = 50
        foreach ($DHCPLease in $DHCPLeases) 
        {
            Write-Progress -Activity "Getting $($DHCPLease.Hostname) status"   -percentComplete ($i / $DHCPLeases.count*100)
            # start a test-connection job for each IP in the range, return the IP and boolean result from test-connection  
            start-job -ArgumentList $DHCPLease.IPAddress -scriptblock { $test = test-connection $args[0] -count 2 -quiet; return $args[0],$test } | out-null  
            # sleep for 3 seconds once groupMax is reached. This code helps prevent security filters from flagging port traffic as malicious for large IP ranges.  
            if ($count -gt $groupMax) {  
                Start-Sleep 3  
                $count = 1
            } else {  
                $count++
            }
            $i++            
        }

        $jobs = get-job | wait-job
        $i = 0
        $resultObject = @() 
        foreach ($job in $jobs) {  
            # grab the job output 
            $temp = receive-job -id $job.id -keep  
            Write-Progress -Activity "Processing data" -Status "$($temp[0])"   -percentComplete ($i / $jobs.count*100)
            $obj = $null
            $obj  = New-Object Object
            $obj  | Add-Member Noteproperty 'IPAddress' -value $temp[0]
                               
            if ($temp[1]) {  
                $obj  | Add-Member Noteproperty 'Status' -value "Online"  
            } else {  
                $obj  | Add-Member Noteproperty 'Status' -value "Offline"  
            }
            $obj  | Add-Member Noteproperty 'MACAddress' -value ($DHCPLeases | Where-Object {$_.IPAddress -eq $temp[0]}).ClientId
            $obj  | Add-Member Noteproperty 'Computername' -value (($DHCPLeases | Where-Object {$_.IPAddress -eq $temp[0]}).HostName).ToUpper()
            $resultObject += $obj            
            $i++   
        }
        # stop and remove all jobs  
        get-job | stop-job  
        get-job | remove-job 
        
        if ($Online)
        {
            Write-Output $($resultObject | Where-Object {$_.Status -eq 'Online'})
        }
        elseif ($Offline)
        {
            Write-Output $($resultObject | Where-Object {$_.Status -eq 'Offline'})
        }
        else
        {
            Write-Output $resultObject
        }

    }
    catch
    {
        throw $Error[0].exception
    }
}