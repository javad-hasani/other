# RAVIX Telegram preflight for Windows PowerShell 5.1+ / PowerShell 7+
# Read-only: checks installed commands and validates BotFather token via
# getMe/getWebhookInfo. Never registers or deletes Telegram webhooks.
# NO secrets are saved to file or printed to the screen.
# Requires network access to https://api.telegram.org and an owner-supplied token.
# Source and changes are tracked in HISTORY.md (RAVIX XRAY-500).
[CmdletBinding()]
param([switch]$SkipTelegram)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ExpectedUsername = 'RavixNetBot'
Write-Host 'RAVIX - Windows and Telegram preflight (read-only)' -ForegroundColor Cyan
Write-Host 'No installation or webhook changes will be performed.'
Write-Host ''
$checks = @('git','php','composer','mysql','docker','wsl')
foreach ($name in $checks) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        Write-Host ('[FOUND]   ' + $name + ' -> ' + $command.Source)
    } else {
        Write-Host ('[MISSING] ' + $name)
    }
}
Write-Host ''
if ($SkipTelegram) {
    Write-Host 'Telegram check skipped. No token requested.'
    return
}
Write-Host 'To verify the existing bot token securely, retrieve it from @BotFather > /mybots.'
Write-Host 'Do NOT paste any token into ChatGPT, GitHub, logs or messages.'
$answer = Read-Host 'Run a read-only Telegram getMe check now? (y/N)'
if ($answer -notin @('y','Y','yes','YES')) {
    Write-Host 'Token test skipped. No Telegram calls performed.'
    return
}
$secureToken = Read-Host 'Paste BotFather token here (input hidden, not saved)' -AsSecureString
$token = $null
try {
    $token = [System.Net.NetworkCredential]::new('', $secureToken).Password
    if ($token -notmatch '^\d{5,}:[A-Za-z0-9_-]{30,}$') {
        Write-Host '[ERROR] Token format appears invalid. Check BotFather privately.' -ForegroundColor Red
        return
    }
    # This is required by Telegram's official Bot API; never log this URL.
    $baseUri = 'https://api.telegram.org/bot' + $token + '/'
    try {
        $me = Invoke-RestMethod -Method Post -Uri ($baseUri + 'getMe') -TimeoutSec 18 -Body @{}
        if ($me.ok -ne $true) {
            Write-Host '[ERROR] Telegram getMe did not return ok=true.' -ForegroundColor Red
            return
        }
        $realName = [string]$me.result.username
        if ($realName -ine $ExpectedUsername) {
            Write-Host ('[STOP] This token belongs to @' + $realName + ', NOT @' + $ExpectedUsername + '. No further calls made.') -ForegroundColor Red
            return
        }
        Write-Host ('[PASS] Telegram getMe confirms @' + $realName) -ForegroundColor Green
    } catch {
        # NEVER print exception.Message; the request URI contains the private token.
        Write-Host '[ERROR] getMe failed. Check internet access, Telegram API reachability and token validity locally.' -ForegroundColor Red
        return
    }
    try {
        $info = Invoke-RestMethod -Method Post -Uri ($baseUri + 'getWebhookInfo') -TimeoutSec 18 -Body @{}
        if ($info.ok -ne $true) {
            Write-Host '[WARN] Could not confirm webhook state.' -ForegroundColor Yellow
            return
        }
        $webhookUrl = [string]$info.result.url
        if (-not [string]::IsNullOrWhiteSpace($webhookUrl)) {
            Write-Host '[ATTENTION] A webhook is already active on this bot. Do NOT connect a second handler yet.' -ForegroundColor Yellow
            # Hostname only; never expose path/secret or complete URL.
            try { Write-Host ('Webhook host only: ' + ([Uri]$webhookUrl).Host) } catch {}
        } else {
            Write-Host '[PASS] No Telegram webhook is currently registered.' -ForegroundColor Green
            Write-Host 'Long polling can be configured once ShahPanel is running locally.'
        }
        $pending = [int]$info.result.pending_update_count
        Write-Host ('Pending updates (count only): ' + $pending)
    } catch {
        Write-Host '[WARN] getWebhookInfo failed. No changes were made.' -ForegroundColor Yellow
    }
} finally {
    # SecureString local scope persists until disposal; .NET immutable strings
    # cannot be guaranteed erased, but no token is written to persistent storage.
    $token = $null
    $secureToken = $null
}
Write-Host 'Done. Share ONLY the [FOUND]/[MISSING]/[PASS]/[WARN] lines; never share the token.'
