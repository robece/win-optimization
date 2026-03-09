#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Restores Windows 11 services and settings that were disabled
    by Optimize-W11DevVM.ps1. Re-enables services to their default
    startup types and reverts registry tweaks.

.NOTES
    Run as Administrator.
    Apps that were removed via Remove-AppxPackage cannot be
    restored with this script. Use the Microsoft Store to
    reinstall them individually, or use System Restore.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  W11 Dev VM — Restore Default Settings" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ─────────────────────────────────────────────
# RE-ENABLE SERVICES
# Default startup types as shipped by Windows 11.
# ─────────────────────────────────────────────

# StartupType reference:
#   Automatic         — starts at boot
#   Manual            — starts on demand
#   Disabled          — never starts

$servicesToRestore = @(

    # ── Telemetry & diagnostics ──────────────────
    @{ Name = "DiagTrack";              StartupType = "Automatic" }
    @{ Name = "dmwappushservice";       StartupType = "Manual" }
    @{ Name = "PcaSvc";                 StartupType = "Manual" }
    @{ Name = "DPS";                    StartupType = "Automatic" }
    @{ Name = "WdiServiceHost";         StartupType = "Manual" }
    @{ Name = "WdiSystemHost";          StartupType = "Manual" }

    # ── Search indexing ───────────────────────────
    @{ Name = "WSearch";                StartupType = "Automatic" }

    # ── Superfetch / SysMain ──────────────────────
    @{ Name = "SysMain";                StartupType = "Automatic" }

    # ── Consumer / retail / gaming features ──────
    @{ Name = "XblAuthManager";         StartupType = "Manual" }
    @{ Name = "XblGameSave";            StartupType = "Manual" }
    @{ Name = "XboxNetApiSvc";          StartupType = "Manual" }
    @{ Name = "XboxGipSvc";             StartupType = "Manual" }
    @{ Name = "GamingServices";         StartupType = "Manual" }
    @{ Name = "spectrum";               StartupType = "Manual" }
    @{ Name = "perceptionsimulation";   StartupType = "Manual" }
    @{ Name = "WMPNetworkSvc";          StartupType = "Manual" }
    @{ Name = "RetailDemo";             StartupType = "Disabled" }
    @{ Name = "MapsBroker";             StartupType = "Automatic" }
    @{ Name = "InstallService";         StartupType = "Manual" }

    # ── Remote / assistance features ─────────────
    @{ Name = "RemoteRegistry";         StartupType = "Disabled" }
    @{ Name = "RemoteAccess";           StartupType = "Disabled" }
    @{ Name = "SessionEnv";             StartupType = "Manual" }
    @{ Name = "TermService";            StartupType = "Manual" }
    @{ Name = "UmRdpService";           StartupType = "Manual" }
    @{ Name = "RasMan";                 StartupType = "Manual" }
    @{ Name = "RasAuto";                StartupType = "Manual" }
    @{ Name = "SstpSvc";                StartupType = "Manual" }

    # ── Printing & scanning ───────────────────────
    @{ Name = "Spooler";                StartupType = "Automatic" }
    @{ Name = "PrintNotify";            StartupType = "Manual" }
    @{ Name = "stisvc";                 StartupType = "Manual" }

    # ── Fax / telephony ───────────────────────────
    @{ Name = "Fax";                    StartupType = "Manual" }
    @{ Name = "TapiSrv";                StartupType = "Manual" }

    # ── Biometrics / sensors ──────────────────────
    @{ Name = "WbioSrvc";               StartupType = "Manual" }
    @{ Name = "SensrSvc";               StartupType = "Manual" }
    @{ Name = "SensorDataService";      StartupType = "Manual" }
    @{ Name = "SensorService";          StartupType = "Manual" }

    # ── Smart card ────────────────────────────────
    @{ Name = "SCardSvr";               StartupType = "Manual" }
    @{ Name = "ScDeviceEnum";           StartupType = "Manual" }
    @{ Name = "SCPolicySvc";            StartupType = "Manual" }

    # ── Parental controls ─────────────────────────
    @{ Name = "WpcMonSvc";              StartupType = "Manual" }

    # ── Bluetooth ─────────────────────────────────
    @{ Name = "bthserv";                StartupType = "Manual" }
    @{ Name = "BTAGService";            StartupType = "Manual" }
    @{ Name = "BthAvctpSvc";            StartupType = "Automatic" }

    # ── Tablet / touch / camera ───────────────────
    @{ Name = "TabletInputService";     StartupType = "Manual" }
    @{ Name = "FrameServer";            StartupType = "Manual" }

    # ── Error reporting ───────────────────────────
    @{ Name = "wercplsupport";          StartupType = "Manual" }
    @{ Name = "WerSvc";                 StartupType = "Manual" }

    # ── Secondary logon ───────────────────────────
    @{ Name = "seclogon";               StartupType = "Manual" }

    # ── Offline files ─────────────────────────────
    @{ Name = "CscService";             StartupType = "Automatic" }

    # ── HomeGroup (legacy) ────────────────────────
    @{ Name = "HomeGroupListener";      StartupType = "Manual" }
    @{ Name = "HomeGroupProvider";      StartupType = "Manual" }
)

$restored = 0
$notFound = 0

Write-Host "Restoring services..." -ForegroundColor Cyan
Write-Host ""

foreach ($svc in $servicesToRestore) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($null -eq $service) {
        Write-Host "  [NOT FOUND] $($svc.Name)" -ForegroundColor DarkGray
        $notFound++
        continue
    }

    Set-Service -Name $svc.Name -StartupType $svc.StartupType
    Write-Host "  [RESTORED]  $($svc.Name) → $($svc.StartupType)" -ForegroundColor Green
    $restored++
}

# ─────────────────────────────────────────────
# REVERT REGISTRY TWEAKS
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Reverting registry tweaks..." -ForegroundColor Cyan

# Cortana
$cortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
if (Test-Path $cortanaPath) {
    Remove-ItemProperty -Path $cortanaPath -Name "AllowCortana" -ErrorAction SilentlyContinue
    Write-Host "  [REG] Cortana policy removed" -ForegroundColor Green
}

# Telemetry
$telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (Test-Path $telemetryPath) {
    Remove-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -ErrorAction SilentlyContinue
    Write-Host "  [REG] Telemetry policy removed" -ForegroundColor Green
}

# Advertising ID
$adPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
if (Test-Path $adPath) {
    Set-ItemProperty -Path $adPath -Name "Enabled" -Value 1 -Type DWord
    Write-Host "  [REG] Advertising ID re-enabled" -ForegroundColor Green
}

# ─────────────────────────────────────────────
# REVERT CPU TWEAKS
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Reverting CPU optimizations..." -ForegroundColor Cyan

# Power plan: Balanced (default)
$balancedGuid = (powercfg /list | Select-String "Balanced" | ForEach-Object {
    if ($_ -match "\(([0-9a-f-]{36})\)") { $Matches[1] }
})
if ($balancedGuid) {
    powercfg /setactive $balancedGuid | Out-Null
    Write-Host "  [POWER] Restored Balanced power plan (GUID: $balancedGuid)" -ForegroundColor Green
}

# Visual effects: Windows default (let Windows decide)
$visualFxPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
if (Test-Path $visualFxPath) {
    Set-ItemProperty -Path $visualFxPath -Name "VisualFXSetting" -Value 0 -Type DWord
    Write-Host "  [VISUAL] Visual effects reset to Windows default" -ForegroundColor Green
}

# Taskbar animations
$explorerAdvPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $explorerAdvPath -Name "TaskbarAnimations" -Value 1 -Type DWord
Write-Host "  [VISUAL] Taskbar animations re-enabled" -ForegroundColor Green

# Background apps
$bgAppsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
if (Test-Path $bgAppsPath) {
    Set-ItemProperty -Path $bgAppsPath -Name "GlobalUserDisabled" -Value 0 -Type DWord
    Write-Host "  [BKGD] Background app access restored" -ForegroundColor Green
}

# Game Bar / DVR
$gameDVRPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
if (Test-Path $gameDVRPath) {
    Set-ItemProperty -Path $gameDVRPath -Name "AppCaptureEnabled" -Value 1 -Type DWord
}
$gameStorePath = "HKCU:\System\GameConfigStore"
if (Test-Path $gameStorePath) {
    Set-ItemProperty -Path $gameStorePath -Name "GameDVR_Enabled" -Value 1 -Type DWord
}
$gamePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
if (Test-Path $gamePolicyPath) {
    Remove-ItemProperty -Path $gamePolicyPath -Name "AllowGameDVR" -ErrorAction SilentlyContinue
}
Write-Host "  [GAME] Game Bar and Game DVR restored" -ForegroundColor Green

# Taskbar Widgets
$widgetPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (Test-Path $widgetPath) {
    Remove-ItemProperty -Path $widgetPath -Name "AllowNewsAndInterests" -ErrorAction SilentlyContinue
    Write-Host "  [WIDGET] Taskbar Widgets policy removed" -ForegroundColor Green
}

# Processor scheduling: Programs (Windows default = 2)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
    -Name "Win32PrioritySeparation" -Value 2 -Type DWord
Write-Host "  [SCHED] Processor scheduling reset to Programs (default)" -ForegroundColor Green

# ─────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RESTORE COMPLETE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Services restored   : $restored"    -ForegroundColor Green
Write-Host "  Services not found  : $notFound"    -ForegroundColor DarkGray
Write-Host ""
Write-Host "  NOTE: Removed apps cannot be restored"    -ForegroundColor Yellow
Write-Host "  via this script. Use the Microsoft Store" -ForegroundColor Yellow
Write-Host "  or System Restore (created at optimize    -ForegroundColor Yellow
  time) to recover them."                               -ForegroundColor Yellow
Write-Host ""
Write-Host "  REBOOT RECOMMENDED to apply all changes." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
