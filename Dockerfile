FROM mcr.microsoft.com/azure-powershell:latest
WORKDIR /workdir
COPY scan_azure_dns.ps1 /workdir/scan_azure_dns.ps1
ENTRYPOINT ["pwsh", "/workdir/scan_azure_dns.ps1"]
