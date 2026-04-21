param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,
    [switch]$WhatIfMode = $true
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CsvPath)) {
    throw "CSV file not found: $CsvPath"
}

if (-not (Get-AzContext -ErrorAction SilentlyContinue)) {
    Connect-AzAccount | Out-Null
}

$rows = Import-Csv -Path $CsvPath

if (-not $rows) {
    Write-Host "[+] No entries found in $CsvPath"
    exit 0
}

foreach ($row in $rows) {
    Write-Host "=================================================="
    Write-Host "Subscription: $($row.SubscriptionName)"
    Write-Host "Deleting Record: $($row.CNAME)"

    Set-AzContext -Subscription $row.SubscriptionName | Out-Null

    if ($WhatIfMode) {
        Write-Host "[DRY-RUN] Remove-AzDnsRecordSet -Name $($row.RecordSetName) -ZoneName $($row.ZoneName) -ResourceGroupName $($row.ResourceGroupName) -RecordType CNAME"
        continue
    }

    Remove-AzDnsRecordSet         -Name $row.RecordSetName         -ZoneName $row.ZoneName         -ResourceGroupName $row.ResourceGroupName         -RecordType CNAME         -Confirm:$false

    Write-Host "[+] DONE"
}
