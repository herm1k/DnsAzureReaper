param(
    [string]$OutputDirectory = "./out",
    [switch]$UseDeviceAuthentication
)

$ErrorActionPreference = "Stop"
$PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::PlainText

$Banner = @"
                 ...
               ;::::;
             ;::::; :;
           ;:::::'   :;
          ;:::::;     ;.
         ,:::::'       ;           ___
         ::::::;       ;        .-`   `-.
         ;:::::;       ;      .'  .-. .-.`.
        ,;::::::;     ;'     /   /  | |  \ \
      ;:::::::::`. ,,,;.    |    \_/   \_/ |
    .';:::::::::::::::::;,  |  .----. .----.|
   ,::::::;::::::;;;;::::;, |  |    | |    ||
  ;`::::::`'::::::;;;:::::  |  | AZ | | UR ||
  :`:::::::`;::::::;;:::    |  |____| |____||
  ::`:::::::`;::::::::      |     CLOUD     |
  `:`:::::::`;::::::        |   abandoned   |
   :::`:::::::`;;           |   resources   |
   ::::`:::::::`            \               /
   `:::::`::::::::::::;'     `-._       _.-'
    `:::::`::::::::;'            `-----'

      _                             ____                             
     / \    _____   _ _ __ ___     |  _ \ ___  __ _ _ __   ___ _ __ 
    / _ \  |_  / | | | '__/ _ \    | |_) / _ \/ _` | '_ \ / _ \ '__|
   / ___ \  / /| |_| | | |  __/    |  _ <  __/ (_| | |_) |  __/ |   
  /_/   \_\/___|\__,_|_|  \___|    |_| \_\___|\__,_| .__/ \___|_|   
                                                    |_|              
"@

Write-Host "`n$Banner`n"

if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    throw "Az PowerShell modules are required. Install-Module Az -Scope CurrentUser"
}

if (-not (Get-Module -ListAvailable -Name Az.Network)) {
    throw "Az.Network module is required. Install-Module Az -Scope CurrentUser"
}

if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) {
    if ($UseDeviceAuthentication) {
        Connect-AzAccount -UseDeviceAuthentication | Out-Null
    } else {
        Connect-AzAccount | Out-Null
    }
}

$resources = @()
$candidates = @()
$subscriptions = Get-AzSubscription

Write-Host "[+] Subscriptions available: $($subscriptions.Count)"

foreach ($subscription in $subscriptions) {
    Write-Host "============================================================================="
    Write-Host "[!] Subscription: $($subscription.Name)"
    Set-AzContext -SubscriptionId $subscription.Id | Out-Null

    try {
        $zones = Get-AzDnsZone -ErrorAction Stop
    } catch {
        Write-Host "[+] No DNS zones or no access in this subscription"
        continue
    }

    foreach ($zone in $zones) {
        $recordSets = Get-AzDnsRecordSet -ZoneName $zone.Name -ResourceGroupName $zone.ResourceGroupName -RecordType CNAME

        foreach ($recordSet in $recordSets) {
            foreach ($record in $recordSet.Records) {
                $target = [string]$record.Cname
                $fqdn = if ($recordSet.Name -eq "@") { $zone.Name } else { "$($recordSet.Name).$($zone.Name)" }
                $resolved = $false
                $reason = ""
                $resolvedIPs = @()

                try {
                    $dnsResults = Resolve-DnsName -Name $target -Type A -ErrorAction Stop
                    $resolvedIPs = $dnsResults | Select-Object -ExpandProperty IPAddress
                    if ($resolvedIPs) {
                        $resolved = $true
                    }
                } catch {
                    try {
                        $dns6Results = Resolve-DnsName -Name $target -Type AAAA -ErrorAction Stop
                        $resolvedIPs = $dns6Results | Select-Object -ExpandProperty IPAddress
                        if ($resolvedIPs) {
                            $resolved = $true
                        }
                    } catch {
                        $reason = "No public A/AAAA resolution observed"
                    }
                }

                $resources += [PSCustomObject]@{
                    SubscriptionName = $subscription.Name
                    ResourceGroupName = $zone.ResourceGroupName
                    ZoneName = $zone.Name
                    RecordName = $fqdn
                    Target = $target
                    Resolved = $resolved
                    ResolvedIPs = ($resolvedIPs -join ';')
                }

                if (-not $resolved) {
                    Write-Host "[!!] Candidate`t$fqdn`t=>`t$target"
                    $candidates += [PSCustomObject]@{
                        CNAME = $fqdn
                        Target = $target
                        ResourceGroupName = $zone.ResourceGroupName
                        SubscriptionName = $subscription.Name
                        RecordSetName = $recordSet.Name
                        ZoneName = $zone.Name
                        Reason = $reason
                    }
                }
            }
        }
    }
}

$resources | Export-Csv -Path (Join-Path $OutputDirectory 'AzureRecords.csv') -NoTypeInformation
$candidates | Export-Csv -Path (Join-Path $OutputDirectory 'vulnerable_cnames.csv') -NoTypeInformation

Write-Host "`n[+] Scan complete"
Write-Host "[+] Records exported to $(Join-Path $OutputDirectory 'AzureRecords.csv')"
Write-Host "[+] Candidates exported to $(Join-Path $OutputDirectory 'vulnerable_cnames.csv')"
