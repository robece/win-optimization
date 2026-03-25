#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Royal XP Theme for Windows 11 -- with full Rollback support.

.DESCRIPTION
    Applies a Royal Blue (XP-inspired) visual theme via registry:
    - Royal Blue accent color on taskbar and title bars
    - Light mode (classic XP era look)
    - Optimized window colorization

    Before applying any change, a backup of the current registry
    values is saved to: .\royal-theme-backup.json

.PARAMETER Rollback
    Restores the previous registry values from the backup file.

.EXAMPLES
    # Apply Royal theme:
    .\Set-RoyalTheme.ps1

    # Undo and restore previous theme:
    .\Set-RoyalTheme.ps1 -Rollback
#>

param(
    [switch]$Rollback
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$backupFile = "$PSScriptRoot\royal-theme-backup.json"

# ─────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────

function Write-Header($text) {
    Write-Host ""
    Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkBlue
    Write-Host "  $text" -ForegroundColor Blue
    Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkBlue
}

function Write-Section($text) {
    Write-Host ""
    Write-Host "  ── $text" -ForegroundColor Cyan
}

function Write-OK($msg)   { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-INFO($msg) { Write-Host "  [--]   $msg" -ForegroundColor DarkGray }
function Write-WARN($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-ERR($msg)  { Write-Host "  [ERR]  $msg" -ForegroundColor Red }

# Registry keys and values managed by this script
# Format: @{ Path; Name; Type }
$managedKeys = @(
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "AppsUseLightTheme";    Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "SystemUsesLightTheme"; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "ColorPrevalence";      Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\DWM";                               Name = "AccentColor";          Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\DWM";                               Name = "AccentColorInactive";  Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\DWM";                               Name = "ColorizationColor";    Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\DWM";                               Name = "ColorizationAfterglow"; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\DWM";                               Name = "EnableWindowColorization"; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\DWM";                               Name = "ColorizationColorBalance"; Type = "DWord" }
)

# ─────────────────────────────────────────────────────────────────────
# BACKUP
# ─────────────────────────────────────────────────────────────────────

function Save-Backup {
    Write-Section "Saving current registry values..."

    $backup = @()
    foreach ($key in $managedKeys) {
        $entry = @{
            Path    = $key.Path
            Name    = $key.Name
            Type    = $key.Type
            Existed = $false
            Value   = $null
        }

        if (Test-Path $key.Path) {
            $prop = Get-ItemProperty -Path $key.Path -Name $key.Name -ErrorAction SilentlyContinue
            if ($null -ne $prop) {
                $entry.Existed = $true
                $entry.Value   = $prop.($key.Name)
            }
        }

        $backup += $entry
    }

    $backup | ConvertTo-Json -Depth 5 | Set-Content -Path $backupFile -Encoding UTF8 -Force
    Write-OK "Backup saved to: $backupFile"
}

# ─────────────────────────────────────────────────────────────────────
# SET REGISTRY VALUE
# ─────────────────────────────────────────────────────────────────────

function Set-RegValue($path, $name, $value, $type = "DWord") {
    try {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force -ErrorAction Stop
        return $true
    } catch {
        Write-WARN "Could not set '$name': $_"
        return $false
    }
}

# ─────────────────────────────────────────────────────────────────────
# RESTART EXPLORER
# ─────────────────────────────────────────────────────────────────────

function Restart-Explorer {
    Write-Section "Restarting Explorer to apply changes..."
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process "explorer.exe"
    Write-OK "Explorer restarted"
}

# ─────────────────────────────────────────────────────────────────────
# ROLLBACK
# ─────────────────────────────────────────────────────────────────────

if ($Rollback) {
    Write-Header "Royal XP Theme -- ROLLBACK"

    if (-not (Test-Path $backupFile)) {
        Write-ERR "Backup file not found: $backupFile"
        Write-ERR "Cannot rollback -- no backup was saved."
        exit 1
    }

    Write-Section "Reading backup from: $backupFile"
    $backup = Get-Content -Path $backupFile -Raw | ConvertFrom-Json

    Write-Section "Restoring registry values..."

    foreach ($entry in $backup) {
        if ($entry.Existed -eq $false) {
            # Value did not exist before -- remove it
            $prop = Get-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
            if ($null -ne $prop) {
                Remove-ItemProperty -Path $entry.Path -Name $entry.Name -Force -ErrorAction SilentlyContinue
                Write-OK "Removed (was not present before): $($entry.Name)"
            } else {
                Write-INFO "Already absent: $($entry.Name)"
            }
        } else {
            # Value existed -- restore it
            $ok = Set-RegValue $entry.Path $entry.Name $entry.Value $entry.Type
            if ($ok) {
                Write-OK "Restored: $($entry.Name) = $($entry.Value)"
            }
        }
    }

    Restart-Explorer

    Write-Host ""
    Write-Host "  ════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  ROLLBACK COMPLETE" -ForegroundColor Green
    Write-Host "  ════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Your previous theme has been fully restored." -ForegroundColor White
    Write-Host ""
    exit 0
}

# ─────────────────────────────────────────────────────────────────────
# APPLY ROYAL THEME
# ─────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkBlue
Write-Host "  Royal XP Theme for Windows 11" -ForegroundColor Blue
Write-Host "  ════════════════════════════════════════════" -ForegroundColor DarkBlue
Write-Host ""

# Step 1: backup current state
Save-Backup

# ── Light Mode ──────────────────────────────────────────────────────
Write-Section "1. Light Mode (classic XP era)"

Set-RegValue `
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
    "AppsUseLightTheme" 1 | Out-Null
Write-OK "Apps: Light mode"

Set-RegValue `
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
    "SystemUsesLightTheme" 1 | Out-Null
Write-OK "System: Light mode"

# ── Accent Color on taskbar and title bars ───────────────────────────
Write-Section "2. Royal Blue accent on taskbar and title bars"

Set-RegValue `
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
    "ColorPrevalence" 1 | Out-Null
Write-OK "Accent color enabled on taskbar and title bars"

# ── Royal Blue Color Values ──────────────────────────────────────────
#
#   Royal XP Blue: #003399
#   Windows registry stores colors as BGR (not RGB), in DWORD format:
#
#   #003399  →  R=0x00  G=0x33  B=0x99
#   BGR DWORD = 0xFF993300  (0xFF = fully opaque alpha)
#
Write-Section "3. Applying Royal Blue color palette"

# Main accent color (taskbar, start button, active title bar)
Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "AccentColor"         0xFF993300 | Out-Null
Write-OK "AccentColor = Royal Blue (#003399)"

# Inactive title bar (slightly lighter blue)
# #1A4DB5 -> BGR = 0xFF B5 4D 1A = 0xFFB54D1A
Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "AccentColorInactive" 0xFFB54D1A | Out-Null
Write-OK "AccentColorInactive = Muted Royal Blue"

# Window colorization (glass/DWM border)
Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "ColorizationColor"         0xC4003399 | Out-Null
Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "ColorizationAfterglow"     0xC4003399 | Out-Null
Write-OK "ColorizationColor = Royal Blue (80% opacity)"

# Enable window border colorization
Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "EnableWindowColorization"  1 | Out-Null
Write-OK "Window border colorization enabled"

# Color balance (0-100, higher = more saturated)
Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "ColorizationColorBalance"  78 | Out-Null
Write-OK "Color balance = 78 (rich, saturated Royal Blue)"

# ── Apply ────────────────────────────────────────────────────────────
Restart-Explorer

# ── Summary ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ════════════════════════════════════════════" -ForegroundColor Blue
Write-Host "  ROYAL THEME APPLIED" -ForegroundColor Blue
Write-Host "  ════════════════════════════════════════════" -ForegroundColor Blue
Write-Host ""
Write-Host "  What changed:" -ForegroundColor White
Write-Host "  - Light mode (system + apps)"                               -ForegroundColor DarkGray
Write-Host "  - Royal Blue accent (#003399) on taskbar and title bars"    -ForegroundColor DarkGray
Write-Host "  - Royal Blue DWM window colorization"                       -ForegroundColor DarkGray
Write-Host ""
Write-Host "  To undo everything and restore your previous theme:" -ForegroundColor Yellow
Write-Host "  .\Set-RoyalTheme.ps1 -Rollback" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Backup saved at:" -ForegroundColor DarkGray
Write-Host "  $backupFile" -ForegroundColor Gray
Write-Host ""
