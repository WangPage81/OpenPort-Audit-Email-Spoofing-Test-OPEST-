# PowerShell Network & Mail Server Recon Script (Supports Manual & File Input)
param(
    [string[]]$targets  # Allows multiple domains manually
)

# Path to domains.txt
$domainFile = "$env:USERPROFILE\Desktop\domains.txt"

# If no manual input, read from domains.txt
if (-not $targets) {
    if (Test-Path $domainFile) {
        Write-Host "[!] No manual domains provided. Reading from domains.txt" -ForegroundColor Yellow
        $targets = Get-Content $domainFile
    } else {
        Write-Host "Error: No domains provided and domains.txt not found!" -ForegroundColor Red
        Write-Host "Provide domains manually or create domains.txt on the Desktop." -ForegroundColor Yellow
        exit
    }
}

foreach ($target in $targets) {
    Write-Host "`n==============================" -ForegroundColor Cyan
    Write-Host " Running Network & Mail Server Recon on: $target" -ForegroundColor Cyan
    Write-Host "==============================`n" -ForegroundColor Cyan

    # Public IP
    $publicIP = (Invoke-WebRequest -Uri "https://ifconfig.me/ip" -UseBasicParsing).Content
    Write-Host "[+] Public IP Address:" -ForegroundColor Green -NoNewline
    Write-Host " $publicIP" -ForegroundColor White

    # A Record (IP Address)
    $aRecord = (Resolve-DnsName -Name $target -Type A -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress -ErrorAction SilentlyContinue)
    Write-Host "[+] A Record (IP Address):" -ForegroundColor Green -NoNewline
    Write-Host " $aRecord" -ForegroundColor White

    # MX Record (Mail Server)
    $mxRecords = (Resolve-DnsName -Name $target -Type MX -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NameExchange -ErrorAction SilentlyContinue) -join ", "
    if (-not $mxRecords) { $mxRecords = "N/A" }
    Write-Host "[+] MX Records (Mail Server):" -ForegroundColor Green -NoNewline
    Write-Host " $mxRecords" -ForegroundColor White

    # TXT Record (SPF & Other Info)
    $txtRecords = (Resolve-DnsName -Name $target -Type TXT -ErrorAction SilentlyContinue | ForEach-Object { $_.Strings -join " " }) -join "; "
    if (-not $txtRecords) { $txtRecords = "N/A" }
    Write-Host "[+] TXT Records (Including SPF):" -ForegroundColor Green -NoNewline
    Write-Host " $txtRecords" -ForegroundColor White

    # CNAME Record
    $cnameRecord = (Resolve-DnsName -Name $target -Type CNAME -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NameHost -ErrorAction SilentlyContinue)
    if (-not $cnameRecord) { $cnameRecord = "N/A" }
    Write-Host "[+] CNAME Record:" -ForegroundColor Green -NoNewline
    Write-Host " $cnameRecord" -ForegroundColor White

    # SOA Record
    $soaRecord = (Resolve-DnsName -Name $target -Type SOA -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PrimaryServer -ErrorAction SilentlyContinue)
    if (-not $soaRecord) { $soaRecord = "N/A" }
    Write-Host "[+] SOA Record:" -ForegroundColor Green -NoNewline
    Write-Host " $soaRecord" -ForegroundColor White

    # Reverse DNS (PTR Record)
    $ip = (Resolve-DnsName -Name $target -Type A -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress -ErrorAction SilentlyContinue)
    if ($ip) {
        $ptrRecord = (Resolve-DnsName -Name $ip -Type PTR -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NameHost -ErrorAction SilentlyContinue)
        if (-not $ptrRecord) { $ptrRecord = "N/A" }
    } else {
        $ptrRecord = "N/A"
    }
    Write-Host "[+] PTR Record (Reverse DNS Lookup):" -ForegroundColor Green -NoNewline
    Write-Host " $ptrRecord" -ForegroundColor White

    # Whois Lookup (Only if 'whois' is available)
    if (Get-Command "whois" -ErrorAction SilentlyContinue) {
        $whoisInfo = whois $target | Out-String
        Write-Host "[+] Whois Lookup:" -ForegroundColor Green
        Write-Host "$whoisInfo" -ForegroundColor White
    } else {
        Write-Host "[!] Whois command not found. Skipping Whois Lookup." -ForegroundColor Yellow
    }

    # Ping Test
    Write-Host "[+] Pinging $target..." -ForegroundColor Green
    Test-Connection -ComputerName $target -Count 2 | Format-Table -AutoSize

    # TCP Port Scan (Includes All SMTP Ports)
    Write-Host "`n[+] Checking Common TCP Ports (80, 443, 25, 465, 587, 2525, 53, 110, 143, 993, 995):" -ForegroundColor Green
    $ports = @(80, 443, 25, 465, 587, 2525, 53, 110, 143, 993, 995)
    foreach ($port in $ports) {
        $socket = New-Object System.Net.Sockets.TcpClient
        try {
            $socket.Connect($target, $port)
            Write-Host "Port $port is OPEN" -ForegroundColor Green
            $socket.Close()
        } catch {
            Write-Host "Port $port is CLOSED" -ForegroundColor Red
        }
    }

    Write-Host "`n[+] Finished scanning $target`n" -ForegroundColor Cyan
}

Write-Host "[+] Script Execution Completed Successfully." -ForegroundColor Cyan
