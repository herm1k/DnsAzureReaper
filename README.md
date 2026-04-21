# AzureReaper

```text
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
```

AzureReaper is a PowerShell-based discovery and cleanup helper for identifying **orphaned Azure-linked DNS records** and **possible takeover candidates related to abandoned cloud resources**.

It is designed for cases where DNS still points at Azure-hosted services, but the backing application, endpoint, or platform resource may no longer exist.

## What it detects

AzureReaper focuses on stale mappings between DNS and Azure-facing services, especially when the DNS layer outlives the actual cloud resource.

Examples include:

- hostnames pointing to deleted or inactive Azure app endpoints
- DNS records referencing cloud resources that have already been removed
- records that still resolve in part, but no longer map to owned infrastructure
- candidates for manual review where a cloud endpoint may be claimable again

## Why this matters

Modern cloud estates change quickly. Apps are renamed, environments are retired, test resources are deleted, and migrations leave behind DNS that no one fully owns anymore.

That creates two kinds of risk:

### 1. Security risk

In some provider-specific scenarios, a dangling DNS entry can become a takeover opportunity if the referenced cloud resource can be recreated or claimed by someone else. Public takeover research tracks these cases service by service, including Azure-related discussions and fingerprints. :contentReference[oaicite:4]{index=4}

### 2. Operational risk

Even when a record is not exploitable, stale DNS creates confusion:

- broken links and degraded user trust
- noisy monitoring and incident response
- poor infrastructure visibility
- drift between ownership, DNS, and deployed resources

## How it works

AzureReaper is intended to:

1. inspect Azure-related DNS targets
2. compare them against expected or existing cloud resources
3. identify stale, broken, or suspicious mappings
4. export findings for remediation or manual validation
5. support cleanup workflows for abandoned cloud-connected records

Like DNSReaper, this tool is meant to identify **high-value review candidates**, not to make automated exploitability claims.

## When to use it

AzureReaper is useful for:

- Azure environment hygiene
- attack surface reviews
- pre-migration and post-migration cleanup
- periodic checks for abandoned app endpoints
- finding DNS drift after cloud resource lifecycle changes

## Reference material

For public takeover research and fingerprints, see:

- **EdOverflow / can-i-take-over-xyz** — a widely used community reference covering services, claimability status, and example fingerprints for dangling DNS / takeover research. :contentReference[oaicite:5]{index=5}

That reference should be used as supporting context, not as definitive proof for any individual hostname. The project itself warns that entries are community-maintained and that exploitability still needs to be validated case by case. :contentReference[oaicite:6]{index=6}
## Usage

AzureReaper is intended to help review Azure-linked DNS records and detect entries that may no longer point to owned or active cloud resources.

### Run the scan

```powershell
pwsh ./scan_azure_dns.ps1 -InputCsv .\sample_targets.csv -OutputCsv .\results.csv
```

### Example with verbose output

```powershell
pwsh ./scan_azure_dns.ps1 -InputCsv .\sample_targets.csv -OutputCsv .\results.csv -Verbose
```

### Cleanup / follow-up mode

If your project includes a cleanup helper, use it carefully and prefer dry-run first.

```powershell
pwsh ./delete_records.ps1 -InputCsv .\results.csv -WhatIf
```

### Common parameters

Typical parameters include:

- `-InputCsv` — CSV file containing hostnames or Azure-linked targets to inspect
- `-OutputCsv` — destination file for findings
- `-Verbose` — print additional scan details
- `-WhatIf` — simulate cleanup actions without making changes

### Expected input

AzureReaper usually works from a CSV list of candidate hostnames, endpoints, or DNS records associated with Azure-hosted services.

Example:

```csv
hostname
app.example.com
old-api.example.com
staging-portal.example.com
```

### Output

AzureReaper writes a CSV report with entries that appear stale, unresolved, unowned, or otherwise suspicious enough for manual review.

### Expected workflow

1. export or prepare a list of Azure-linked hostnames
2. run AzureReaper against the list
3. review flagged records
4. validate whether the backing Azure resource still exists and is owned
5. clean up or remediate stale mappings

## Important note

AzureReaper helps answer:

- “Does this DNS record still map to something we own?”
- “Is this Azure-linked endpoint stale?”
- “Should this hostname be reviewed or removed?”

It does **not** automatically prove that a takeover is possible.
Manual validation is still required.
