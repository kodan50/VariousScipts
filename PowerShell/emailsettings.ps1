<#
.SYNOPSIS
  Guess the best IMAP/SMTP settings for an e-mail address (Windows PowerShell 5.1+, no dependencies).
.EXAMPLE
  .\emailsettings.ps1 user@example.com
  .\emailsettings.ps1 user@example.com -NoProbe
  .\emailsettings.ps1 user@example.com -Json
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Email,
    [switch]$NoProbe,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$Timeout = 6
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 }
catch { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 }

# imap host, smtp host
$Known = @{
    'gmail.com'      = @('imap.gmail.com', 'smtp.gmail.com')
    'googlemail.com' = @('imap.gmail.com', 'smtp.gmail.com')
    'outlook.com'    = @('outlook.office365.com', 'smtp.office365.com')
    'hotmail.com'    = @('outlook.office365.com', 'smtp.office365.com')
    'live.com'       = @('outlook.office365.com', 'smtp.office365.com')
    'msn.com'        = @('outlook.office365.com', 'smtp.office365.com')
    'yahoo.com'      = @('imap.mail.yahoo.com', 'smtp.mail.yahoo.com')
    'ymail.com'      = @('imap.mail.yahoo.com', 'smtp.mail.yahoo.com')
    'aol.com'        = @('imap.aol.com', 'smtp.aol.com')
    'icloud.com'     = @('imap.mail.me.com', 'smtp.mail.me.com')
    'me.com'         = @('imap.mail.me.com', 'smtp.mail.me.com')
    'mac.com'        = @('imap.mail.me.com', 'smtp.mail.me.com')
    'fastmail.com'   = @('imap.fastmail.com', 'smtp.fastmail.com')
    'zoho.com'       = @('imap.zoho.com', 'smtp.zoho.com')
    'gmx.com'        = @('imap.gmx.com', 'mail.gmx.com')
    'gmx.net'        = @('imap.gmx.net', 'mail.gmx.net')
    'mail.com'       = @('imap.mail.com', 'smtp.mail.com')
}

# MX suffix -> imap, smtp, name
$MxProviders = [ordered]@{
    'google.com'                  = @('imap.gmail.com', 'smtp.gmail.com', 'Google Workspace')
    'googlemail.com'              = @('imap.gmail.com', 'smtp.gmail.com', 'Google Workspace')
    'mail.protection.outlook.com' = @('outlook.office365.com', 'smtp.office365.com', 'Microsoft 365')
    'zoho.com'                    = @('imap.zoho.com', 'smtp.zoho.com', 'Zoho Mail')
    'zoho.eu'                     = @('imap.zoho.eu', 'smtp.zoho.eu', 'Zoho Mail EU')
    'messagingengine.com'         = @('imap.fastmail.com', 'smtp.fastmail.com', 'Fastmail')
    'yahoodns.net'                = @('imap.mail.yahoo.com', 'smtp.mail.yahoo.com', 'Yahoo')
    'icloud.com'                  = @('imap.mail.me.com', 'smtp.mail.me.com', 'iCloud')
    'secureserver.net'            = @('imap.secureserver.net', 'smtpout.secureserver.net', 'GoDaddy')
    'emailsrvr.com'               = @('secure.emailsrvr.com', 'secure.emailsrvr.com', 'Rackspace')
    'mxlogin.com'                 = @('imap.mxlogin.com', 'smtp.mxlogin.com', 'Namecheap/Titan')
}

function Get-Web([string]$Url, [hashtable]$Headers = @{}) {
    try {
        $r = Invoke-WebRequest -Uri $Url -Headers $Headers -UseBasicParsing -TimeoutSec $Timeout
        # PS 5.1 returns byte[] for unknown content types (e.g. application/dns-json)
        if ($r.Content -is [byte[]]) { return [Text.Encoding]::UTF8.GetString($r.Content) }
        return [string]$r.Content
    } catch { return $null }
}

# DNS over HTTPS (Cloudflare) - PowerShell 5.1 has no portable SRV/MX resolver
function Resolve-Doh([string]$Name, [string]$Type) {
    $url = 'https://cloudflare-dns.com/dns-query?name={0}&type={1}' -f [uri]::EscapeDataString($Name), $Type
    $txt = Get-Web $url @{ Accept = 'application/dns-json' }
    if (-not $txt) { return @() }
    try {
        $j = $txt | ConvertFrom-Json
        if ($j.Answer) { return @($j.Answer | ForEach-Object { $_.data }) }
    } catch {}
    return @()
}

function New-Cand($Proto, $HostName, $Port, $Sec, $Source) {
    @{ proto = $Proto; host = $HostName; port = [int]$Port; security = $Sec; source = $Source; verified = $null; cert_ok = $null }
}

function Get-Defaults($ImapHost, $SmtpHost, $Source) {
    @(
        (New-Cand 'imap' $ImapHost 993 'SSL/TLS' $Source)
        (New-Cand 'imap' $ImapHost 143 'STARTTLS' $Source)
        (New-Cand 'smtp' $SmtpHost 465 'SSL/TLS' $Source)
        (New-Cand 'smtp' $SmtpHost 587 'STARTTLS' $Source)
    )
}

function Read-Autoconfig([string]$XmlText, [string]$Domain, [string]$Source) {
    $out = @()
    try { $x = [xml]$XmlText } catch { return $out }
    $servers = @()
    foreach ($n in $x.SelectNodes('//incomingServer[@type="imap"]')) { $servers += , @('imap', $n) }
    foreach ($n in $x.SelectNodes('//outgoingServer[@type="smtp"]')) { $servers += , @('smtp', $n) }
    foreach ($s in $servers) {
        $n = $s[1]
        $h = ([string]$n.hostname).Replace('%EMAILDOMAIN%', $Domain)
        $p = [string]$n.port
        if (-not $h -or -not $p) { continue }
        $sec = switch (([string]$n.socketType).ToUpper()) { 'SSL' { 'SSL/TLS' } 'STARTTLS' { 'STARTTLS' } 'PLAIN' { 'None' } default { [string]$n.socketType } }
        $out += , (New-Cand $s[0] $h $p $sec $Source)
    }
    return $out
}

function Get-Autoconfig([string]$Domain) {
    $urls = @(
        @('domain autoconfig', "https://autoconfig.$Domain/mail/config-v1.1.xml"),
        @('domain well-known', "https://$Domain/.well-known/autoconfig/mail/config-v1.1.xml"),
        @('Mozilla ISPDB', "https://autoconfig.thunderbird.net/v1.1/$Domain")
    )
    foreach ($u in $urls) {
        $data = Get-Web $u[1]
        if ($data -and $data -match '<clientConfig') {
            $res = @(Read-Autoconfig $data $Domain $u[0])
            if ($res.Count) { return $res }
        }
    }
    return @()
}

function Get-SrvCands([string]$Domain) {
    $out = @()
    $q = @(
        @('imap', '_imaps._tcp', 'SSL/TLS'), @('imap', '_imap._tcp', 'STARTTLS'),
        @('smtp', '_submissions._tcp', 'SSL/TLS'), @('smtp', '_submission._tcp', 'STARTTLS')
    )
    foreach ($e in $q) {
        foreach ($rec in (Resolve-Doh "$($e[1]).$Domain" 'SRV')) {
            $p = $rec -split '\s+'
            if ($p.Count -eq 4 -and $p[3] -ne '.') { $out += , (New-Cand $e[0] $p[3].TrimEnd('.') $p[2] $e[2] 'SRV (RFC 6186)') }
        }
    }
    return $out
}

function Get-MxRecords([string]$Domain) {
    $rows = foreach ($rec in (Resolve-Doh $Domain 'MX')) {
        $p = $rec -split '\s+'
        if ($p.Count -eq 2) { [pscustomobject]@{ Pri = [int]$p[0]; Host = $p[1].TrimEnd('.').ToLower() } }
    }
    return @($rows | Sort-Object Pri)
}

function Get-MxHosts([string]$Domain) {
    return @(Get-MxRecords $Domain | ForEach-Object { $_.Host })
}

function Get-MxCands([string]$Domain, $Mx) {
    foreach ($m in $Mx) {
        foreach ($suffix in $MxProviders.Keys) {
            if ($m -eq $suffix -or $m.EndsWith(".$suffix")) {
                $v = $MxProviders[$suffix]
                return @(Get-Defaults $v[0] $v[1] ("MX -> " + $v[2]))
            }
        }
        $parts = $m.Split('.')
        $base = ($parts[-2..-1]) -join '.'
        if ($base -ne $Domain) {
            $data = Get-Web "https://autoconfig.thunderbird.net/v1.1/$base"
            if ($data -and $data -match '<clientConfig') {
                $res = @(Read-Autoconfig $data $base "MX -> ISPDB($base)")
                if ($res.Count) { return $res }
            }
        }
    }
    return @()
}

function Get-Guesses([string]$Domain, $Mx) {
    $mx2 = @($Mx | Select-Object -First 2)
    $out = @()
    foreach ($h in (@("imap.$Domain", "mail.$Domain", $Domain) + $mx2 | Select-Object -Unique)) {
        $out += , (New-Cand 'imap' $h 993 'SSL/TLS' 'guess')
        $out += , (New-Cand 'imap' $h 143 'STARTTLS' 'guess')
    }
    foreach ($h in (@("smtp.$Domain", "mail.$Domain", $Domain) + $mx2 | Select-Object -Unique)) {
        $out += , (New-Cand 'smtp' $h 465 'SSL/TLS' 'guess')
        $out += , (New-Cand 'smtp' $h 587 'STARTTLS' 'guess')
    }
    return $out
}

# Runs inside runspaces. Connects, checks banner (+ STARTTLS) and TLS certificate validity.
$ProbeScript = {
    param($c, $timeoutSec)
    $ms = $timeoutSec * 1000
    function Read-Chunk($stream) {
        $buf = New-Object byte[] 2048
        $n = $stream.Read($buf, 0, $buf.Length)
        if ($n -le 0) { return '' }
        return [Text.Encoding]::ASCII.GetString($buf, 0, $n)
    }
    function Send-Line($stream, $text) {
        $b = [Text.Encoding]::ASCII.GetBytes($text + "`r`n")
        $stream.Write($b, 0, $b.Length); $stream.Flush()
    }
    function Test-Banner($proto, $text) {
        if ($proto -eq 'imap') { return $text.StartsWith('* OK') } else { return $text.StartsWith('220') }
    }
    function Invoke-Probe($c, $ms, $lax) {
        $tcp = New-Object Net.Sockets.TcpClient
        try {
            $iar = $tcp.BeginConnect($c.host, $c.port, $null, $null)
            if (-not $iar.AsyncWaitHandle.WaitOne($ms)) { throw 'connect timeout' }
            $tcp.EndConnect($iar)
            $tcp.ReceiveTimeout = $ms; $tcp.SendTimeout = $ms
            $stream = $tcp.GetStream()
            $stream.ReadTimeout = $ms
            $cb = $null
            if ($lax) { $cb = [Net.Security.RemoteCertificateValidationCallback] { $true } }
            if ($c.security -eq 'SSL/TLS') {
                $ssl = New-Object Net.Security.SslStream($stream, $false, $cb)
                $ssl.AuthenticateAsClient($c.host)
                return (Test-Banner $c.proto (Read-Chunk $ssl))
            }
            if ($c.security -eq 'STARTTLS') {
                if (-not (Test-Banner $c.proto (Read-Chunk $stream))) { return $false }
                if ($c.proto -eq 'imap') {
                    Send-Line $stream 'a1 STARTTLS'
                    if ((Read-Chunk $stream) -notmatch 'a1 OK') { return $false }
                } else {
                    Send-Line $stream 'EHLO probe.local'
                    $resp = ''
                    while ($resp -notmatch '(?m)^250 ') {
                        $chunk = Read-Chunk $stream
                        if (-not $chunk) { break }
                        $resp += $chunk
                    }
                    if ($resp -notmatch '(?i)STARTTLS') { return $false }
                    Send-Line $stream 'STARTTLS'
                    if (-not (Read-Chunk $stream).StartsWith('220')) { return $false }
                }
                $ssl = New-Object Net.Security.SslStream($stream, $false, $cb)
                $ssl.AuthenticateAsClient($c.host)
                return $true
            }
            return (Test-Banner $c.proto (Read-Chunk $stream))
        } finally { $tcp.Close() }
    }
    try {
        $c.verified = [bool](Invoke-Probe $c $ms $false)
        $c.cert_ok = $c.verified
    } catch {
        $msg = $_.Exception.ToString()
        if ($msg -match 'AuthenticationException|certificate|RemoteCertificate|SSL') {
            $c.cert_ok = $false
            try { $c.verified = [bool](Invoke-Probe $c $ms $true) } catch { $c.verified = $false }
        } else { $c.verified = $false }
    }
    return $c
}

function Invoke-ProbeAll($Cands) {
    $pool = [runspacefactory]::CreateRunspacePool(1, 12)
    $pool.Open()
    $jobs = foreach ($c in $Cands) {
        $ps = [powershell]::Create()
        $ps.RunspacePool = $pool
        [void]$ps.AddScript($ProbeScript).AddArgument($c).AddArgument($Timeout)
        [pscustomobject]@{ PS = $ps; Handle = $ps.BeginInvoke(); Orig = $c }
    }
    $res = foreach ($j in $jobs) {
        try {
            $r = $j.PS.EndInvoke($j.Handle)
            if ($r -and $r.Count) { $r[-1] } else { $j.Orig.verified = $false; $j.Orig }
        } catch { $j.Orig.verified = $false; $j.Orig }
        $j.PS.Dispose()
    }
    $pool.Close(); $pool.Dispose()
    return @($res)
}

function Get-SecRank($c) { switch ($c.security) { 'SSL/TLS' { 0 } 'STARTTLS' { 1 } default { 2 } } }

function Select-Unique($Cands) {
    $seen = @{}; $out = @()
    foreach ($c in $Cands) {
        $k = "$($c.proto)|$($c.host.ToLower())|$($c.port)|$($c.security)"
        if (-not $seen.ContainsKey($k)) { $seen[$k] = 1; $out += , $c }
    }
    return $out
}

# ---------------- DNS health: MX / SPF / DMARC ----------------
# provider name (from $MxProviders) -> SPF include that sending through it requires
$SpfIncludes = @{
    'Google Workspace' = '_spf.google.com'
    'Microsoft 365'    = 'spf.protection.outlook.com'
    'Zoho Mail'        = 'zoho.com'
    'Zoho Mail EU'     = 'zoho.eu'
    'Fastmail'         = 'spf.messagingengine.com'
}

function Get-TxtRecords([string]$Name) {
    foreach ($raw in (Resolve-Doh $Name 'TXT')) {
        $parts = [regex]::Matches($raw, '"((?:[^"\\]|\\.)*)"')
        if ($parts.Count) { ($parts | ForEach-Object { $_.Groups[1].Value }) -join '' } else { $raw }
    }
}

function Get-SpfRecords([string]$Name) {
    @(Get-TxtRecords $Name | Where-Object { $_ -match '^\s*v=spf1(\s|$)' })
}

# Counts SPF mechanisms that cost a DNS lookup (limit is 10), following include/redirect.
function Get-SpfLookupCount([string]$Spf, [int]$Depth, [hashtable]$Seen) {
    $count = 0
    foreach ($tok in ($Spf -split '\s+')) {
        $t = $tok.TrimStart('+', '-', '~', '?')
        $target = $null
        if ($t -match '^(a|mx|ptr)(:|/|$)' -or $t -match '^exists:') { $count++ }
        elseif ($t -match '^include:(.+)$') { $count++; $target = $Matches[1] }
        elseif ($t -match '^redirect=(.+)$') { $count++; $target = $Matches[1] }
        if ($target -and $Depth -lt 10 -and -not $Seen.ContainsKey($target)) {
            $Seen[$target] = 1
            $rec = @(Get-SpfRecords $target)
            if ($rec.Count) { $count += Get-SpfLookupCount $rec[0] ($Depth + 1) $Seen }
        }
    }
    return $count
}

function Get-MxProviderName([string]$MxHost) {
    foreach ($suffix in $MxProviders.Keys) {
        if ($MxHost -eq $suffix -or $MxHost.EndsWith(".$suffix")) { return $MxProviders[$suffix][2] }
    }
    return $null
}

function Test-DnsHealth([string]$Domain, $MxRecs) {
    $f = New-Object System.Collections.ArrayList
    function Add-Finding($lvl, $msg) { [void]$f.Add([pscustomobject]@{ level = $lvl; message = $msg }) }

    # ---- MX ----
    $selfMx = @($MxRecs | Where-Object { $_.Host -eq $Domain -or $_.Host.EndsWith(".$Domain") })
    $otherMx = @($MxRecs | Where-Object { $_.Host -ne $Domain -and -not $_.Host.EndsWith(".$Domain") })
    $providers = @($otherMx | ForEach-Object { Get-MxProviderName $_.Host } | Where-Object { $_ } | Select-Object -Unique)
    $unknownOther = @($otherMx | Where-Object { -not (Get-MxProviderName $_.Host) })

    if (-not $MxRecs.Count) {
        Add-Finding 'WARN' "No MX records. Senders fall back to the domain's A record, which is rarely what you want."
    } else {
        foreach ($m in $selfMx) {
            if ($otherMx.Count) {
                Add-Finding 'WARN' ("MX '{0}' (priority {1}) points back at your own domain while other MX hosts exist. If those are unreachable, mail is delivered to that server (often a web host with no mailbox) and may bounce or vanish. Remove it unless intended." -f $m.Host, $m.Pri)
            } else {
                Add-Finding 'INFO' "The only MX ('$($m.Host)') is on your own domain, so mail is self-hosted."
            }
        }
        if ($providers.Count -gt 1) {
            Add-Finding 'WARN' ("MX records point at several providers ({0}). Normally only one provider should receive your mail." -f ($providers -join ', '))
        } elseif ($providers.Count -eq 1 -and $unknownOther.Count) {
            Add-Finding 'WARN' ("MX mixes {0} with other hosts ({1}). Mail may be split between servers." -f $providers[0], (($unknownOther | ForEach-Object { $_.Host }) -join ', '))
        }
        if ($providers.Count -eq 1 -and -not $selfMx.Count -and -not $unknownOther.Count) {
            Add-Finding 'OK' "MX records consistently point at $($providers[0])."
        }
    }

    # ---- SPF ----
    $spfs = @(Get-SpfRecords $Domain)
    if (-not $spfs.Count) {
        if ($MxRecs.Count) { Add-Finding 'WARN' 'No SPF record. Receivers may treat your mail as spam or reject it.' }
    } elseif ($spfs.Count -gt 1) {
        Add-Finding 'WARN' ("{0} SPF records found. Only one is allowed; with several, SPF fails outright (permerror). Merge them into one." -f $spfs.Count)
    } else {
        $spf = $spfs[0]
        $hasRedirect = $spf -match 'redirect='
        if ($spf -match '(?:^|\s)([+\-~?]?)all\s*$') {
            switch ($Matches[1]) {
                '-' { Add-Finding 'OK'   "SPF ends in '-all' (strict: unlisted senders are rejected)." }
                '~' { Add-Finding 'INFO' "SPF ends in '~all' (softfail). That's the common default; use '-all' once you're sure every sender is listed." }
                '?' { Add-Finding 'WARN' "SPF ends in '?all' (neutral), which gives no protection." }
                default { Add-Finding 'WARN' "SPF ends in '+all' (or bare 'all'): it authorizes the entire internet to send as you." }
            }
        } elseif (-not $hasRedirect) {
            Add-Finding 'WARN' "SPF has no 'all' mechanism, so there is no default policy for unlisted senders."
        }

        if (-not $hasRedirect) {
            foreach ($p in $providers) {
                $inc = $SpfIncludes[$p]
                if ($inc -and $spf -notmatch ('include:' + [regex]::Escape($inc))) {
                    Add-Finding 'WARN' "SPF doesn't contain 'include:$inc', but your mail is hosted at $p. Mail sent through $p can fail SPF."
                }
            }
        }

        $lookups = Get-SpfLookupCount $spf 0 @{}
        if ($lookups -gt 10) {
            Add-Finding 'WARN' "SPF needs $lookups DNS lookups (limit is 10). Receivers will return permerror. Remove unused includes."
        } elseif ($lookups -ge 8) {
            Add-Finding 'INFO' "SPF uses $lookups of the 10 allowed DNS lookups; little headroom left."
        }
        if ($spf -match '(?:^|\s)[+\-~?]?ptr(:|\s|$)') { Add-Finding 'WARN' "SPF uses the deprecated 'ptr' mechanism." }

        $ips = @([regex]::Matches($spf, '(?:ip4|ip6):\S+') | ForEach-Object { $_.Value })
        if ($ips.Count) {
            Add-Finding 'INFO' ("SPF authorizes {0} address(es) directly: {1}. Confirm each is still yours." -f $ips.Count, ($ips -join ' '))
        }
        $incl = @([regex]::Matches($spf, 'include:(\S+)') | ForEach-Object { $_.Groups[1].Value })
        $known = @($SpfIncludes.Values) + @('_spf.google.com')
        $unrec = @($incl | Where-Object { $_ -notin $known })
        if ($unrec.Count) {
            Add-Finding 'INFO' ("SPF includes: {0}. Remove any service you no longer send mail through." -f ($unrec -join ', '))
        }
    }

    # ---- DMARC ----
    $dmarc = @(Get-TxtRecords "_dmarc.$Domain" | Where-Object { $_ -match '^\s*v=DMARC1' })
    if (-not $dmarc.Count) {
        Add-Finding 'INFO' 'No DMARC record. Recommended, and required by Google/Yahoo for bulk senders.'
    } elseif ($dmarc[0] -match 'p=none') {
        Add-Finding 'INFO' 'DMARC policy is p=none (monitoring only).'
    } else {
        Add-Finding 'OK' 'DMARC record present with an enforcing policy.'
    }
    return @($f)
}

# ---------------- main ----------------
$Email = $Email.Trim()
if ($Email -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { throw "Not a valid e-mail address: $Email" }
$domain = $Email.Substring($Email.LastIndexOf('@') + 1).ToLower()

if ($domain -in 'proton.me', 'protonmail.com', 'pm.me') {
    Write-Output 'Proton Mail has no direct IMAP/SMTP; use Proton Bridge (127.0.0.1, IMAP 1143, SMTP 1025).'
    return
}

$cands = @()
if ($Known.ContainsKey($domain)) { $cands = @(Get-Defaults $Known[$domain][0] $Known[$domain][1] 'built-in table') }
if (-not $cands.Count) { $cands = @(Get-Autoconfig $domain) }
if (-not $cands.Count) { $cands = @(Get-SrvCands $domain) }
$mxRecords = @(Get-MxRecords $domain)
$mx = @($mxRecords | ForEach-Object { $_.Host })
if (-not $cands.Count) { $cands = @(Get-MxCands $domain $mx) }
if (-not $cands.Count) { $cands = @(Get-Guesses $domain $mx) }
$cands = @(Select-Unique $cands)

$result = @{}
if (-not $NoProbe) {
    $cands = @(Invoke-ProbeAll $cands)
    if (-not (@($cands | Where-Object { $_.verified }).Count)) {
        $have = @{}; foreach ($c in $cands) { $have["$($c.proto)|$($c.host.ToLower())|$($c.port)|$($c.security)"] = 1 }
        $extra = @(Get-Guesses $domain $mx | Where-Object { -not $have.ContainsKey("$($_.proto)|$($_.host.ToLower())|$($_.port)|$($_.security)") })
        if ($extra.Count) { $cands += @(Invoke-ProbeAll $extra) }
    }
    foreach ($p in 'imap', 'smtp') {
        $result[$p] = @($cands | Where-Object { $_.proto -eq $p -and $_.verified } |
            Sort-Object @{ e = { -not $_.cert_ok } }, @{ e = { Get-SecRank $_ } })
    }
} else {
    foreach ($p in 'imap', 'smtp') {
        $result[$p] = @($cands | Where-Object { $_.proto -eq $p } | Sort-Object @{ e = { Get-SecRank $_ } })
    }
}

$dns = @(Test-DnsHealth $domain $mxRecords)

if ($Json) {
    [pscustomobject]@{ email = $Email; imap = $result['imap']; smtp = $result['smtp']; dns_checks = $dns } | ConvertTo-Json -Depth 5
    return
}

Write-Output "Settings for $Email (username: $Email)`n"
foreach ($p in 'imap', 'smtp') {
    Write-Output ($p.ToUpper() + ':')
    $rows = @($result[$p])
    if (-not $rows.Count) { Write-Output "  no working server found`n"; continue }
    for ($i = 0; $i -lt $rows.Count; $i++) {
        $c = $rows[$i]
        $tag = if ($i -eq 0) { 'BEST ' } else { 'alt  ' }
        $note = ''
        if (-not $NoProbe) { $note = if ($c.cert_ok) { '  [reachable]' } else { '  [reachable, CERT NOT VALID]' } }
        Write-Output ('  {0}{1}:{2}  {3}  (via {4}){5}' -f $tag, $c.host, $c.port, $c.security, $c.source, $note)
    }
    Write-Output ''
}
Write-Output 'DNS health (MX / SPF / DMARC):'
foreach ($d in $dns) {
    $tag = switch ($d.level) { 'WARN' { '[WARN]' } 'OK' { '[ ok ]' } default { '[info]' } }
    Write-Output ("  {0} {1}" -f $tag, $d.message)
}
Write-Output ''
if ($NoProbe) { Write-Output '(-NoProbe: results not verified against live servers)' }
