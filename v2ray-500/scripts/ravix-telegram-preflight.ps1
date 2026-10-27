# RAVIX Telegram preflight for Windows PowerShell 5.1+ / PowerShell 7+
# Read-only: checks installed commands and validates BotFather token via
# getMe/getWebhookInfo. Never registers or deletes Telegram webhooks.
# This script never writes secrets to disk or prints them to the screen.
# Optional -FromEnvFile reads a USER-managed local .env outside Git.
# Requires network access to https://api.telegram.org and an owner-supplied token.
# Source and changes are tracked in HISTORY.md (RAVIX XRAY-500).
[CmdletBinding()]
param([switch]$SkipTelegram, [switch]$FromClipboard, [switch]$FromEnvFile)
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
$secureToken = $null
$token = $null
try {
    if ($FromClipboard -and $FromEnvFile) {
        Write-Host '[ERROR] Select either -FromClipboard or -FromEnvFile, not both.' -ForegroundColor Red
        return
    }
    if ($FromEnvFile) {
        # Local file is OUTSIDE the Git checkout and never sent to this repo.
        # Only a single RAVIX_BOT_TOKEN variable is accepted.
        $envPath = Join-Path $env:USERPROFILE '.ravix\.env'
        if (-not (Test-Path -LiteralPath $envPath -PathType Leaf)) {
            Write-Host '[ERROR] Missing private file: ~/.ravix/.env. Create it in VS Code (outside Git).' -ForegroundColor Red
            return
        }
        try {
            $entries = @(Get-Content -LiteralPath $envPath -ErrorAction Stop |
                Where-Object { $_ -match '^RAVIX_BOT_TOKEN\s*=' })
            if ($entries.Count -ne 1) {
                Write-Host '[ERROR] Private file must contain exactly one RAVIX_BOT_TOKEN=... line.' -ForegroundColor Red
                return
            }
            $token = (($entries[0] -replace '^RAVIX_BOT_TOKEN\s*=\s*', '').Trim()).Trim('"').Trim("'").Trim()
            Write-Host '[OK] Local token file loaded (secret not displayed).' -ForegroundColor Green
        } catch {
            Write-Host '[ERROR] Could not read local .env file. No Telegram request made.' -ForegroundColor Red
            return
        }
    } elseif ($FromClipboard) {
        # On some terminals pasted uppercase characters are lost. Reading the
        # Windows clipboard directly avoids the terminal's paste translation.
        # This mode is opt-in. Never print clipboard contents or request URLs.
        Write-Host 'Clipboard mode: copy ONLY the API token from BotFather before running this script.'
        try {
            $token = ([string](Get-Clipboard -Raw -ErrorAction Stop)).Trim()
        } catch {
            Write-Host '[ERROR] Could not read the Windows clipboard. No Telegram calls performed.' -ForegroundColor Red
            return
        }
        try {
            # Immediately overwrite the clipboard so accidental paste will not
            # expose the token in chat, terminals or other apps.
            Set-Clipboard -Value ' ' -ErrorAction Stop
            Write-Host '[OK] Clipboard overwritten after reading token.'
        } catch {
            Write-Host '[WARN] Could not clear clipboard; clear it manually now.' -ForegroundColor Yellow
        }
    } else {
        $secureToken = Read-Host 'Paste BotFather token here (input hidden, not saved)' -AsSecureString
        $token = [System.Net.NetworkCredential]::new('', $secureToken).Password.Trim()
    }
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
