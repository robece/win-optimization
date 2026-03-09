#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Restores Windows 11 services and settings that were disabled
    by Optimize-W11DevVM.ps1 or Optimize-W11DevVM-v2.ps1.
    Re-enables services to their default startup types,
    reverts registry tweaks, and generates a full-color HTML log.

.NOTES
    Run as Administrator.
    Apps removed via Remove-AppxPackage cannot be restored with this
    script. Use the Microsoft Store or System Restore instead.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# ─────────────────────────────────────────────
# HTML LOG ENGINE
# ─────────────────────────────────────────────
$script:htmlLines = [System.Collections.Generic.List[string]]::new()
$script:logPath   = "$PSScriptRoot\restore-log.html"

$colorMap = @{
    Cyan       = "#4ec9e0"
    Yellow     = "#dcdcaa"
    Green      = "#4ec94e"
    Red        = "#f44747"
    DarkGray   = "#666666"
    DarkYellow = "#c8a000"
    White      = "#d4d4d4"
    Gray       = "#9d9d9d"
    Default    = "#d4d4d4"
}

function Write-Log {
    param(
        [string]$Message = "",
        [string]$ForegroundColor = "Default"
    )
    if ($ForegroundColor -ne "Default" -and $ForegroundColor -ne "") {
        Write-Host $Message -ForegroundColor $ForegroundColor
    } else {
        Write-Host $Message
    }
    $css  = if ($colorMap.ContainsKey($ForegroundColor)) { $colorMap[$ForegroundColor] } else { $colorMap["Default"] }
    $safe = $Message -replace "&","&amp;" -replace "<","&lt;" -replace ">","&gt;"
    $safe = if ($safe -eq "") { "&nbsp;" } else { $safe }
    $script:htmlLines.Add("<div><span style='color:$css'>$safe</span></div>")
}

function Save-HtmlLog {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $hostname  = $env:COMPUTERNAME
    $os        = (Get-CimInstance Win32_OperatingSystem).Caption
    $header = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>W11 VM Restore - Log</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background-color: #0c0c0c;
            color: #d4d4d4;
            font-family: 'Cascadia Code', 'Consolas', 'Courier New', monospace;
            font-size: 13px;
            line-height: 1.6;
            padding: 24px 32px;
        }
        .meta {
            color: #555;
            font-size: 11px;
            margin-bottom: 24px;
            border-bottom: 1px solid #1e1e1e;
            padding-bottom: 12px;
        }
        .meta span { color: #4ec9e0; }
        .log { white-space: pre-wrap; }
        div { min-height: 1.6em; }
    </style>
</head>
<body>
    <div class="meta">
        Generated: <span>$timestamp</span> &nbsp;|&nbsp;
        Host: <span>$hostname</span> &nbsp;|&nbsp;
        OS: <span>$os</span>
    </div>
    <div class="log">
"@
    $footer = "</div></body></html>"
    $content = $header + ($script:htmlLines -join "`n") + $footer
    [System.IO.File]::WriteAllText($script:logPath, $content, [System.Text.Encoding]::UTF8)
    Write-Host ""
    Write-Host "  HTML log saved to: $script:logPath" -ForegroundColor Cyan
}

# ─────────────────────────────────────────────
# HEADER
# ─────────────────────────────────────────────
Write-Log ""
Write-Log "============================================" Cyan
Write-Log "  W11 Dev VM - Restore Default Settings" Cyan
Write-Log "============================================" Cyan
Write-Log ""

# ─────────────────────────────────────────────
# RE-ENABLE SERVICES
# ─────────────────────────────────────────────
$servicesToRestore = @(
    @{ Name = "DiagTrack";              StartupType = "Automatic" }
    @{ Name = "dmwappushservice";       StartupType = "Manual" }
    @{ Name = "PcaSvc";                 StartupType = "Manual" }
    @{ Name = "DPS";                    StartupType = "Automatic" }
    @{ Name = "WdiServiceHost";         StartupType = "Manual" }
    @{ Name = "WdiSystemHost";          StartupType = "Manual" }
    @{ Name = "WSearch";                StartupType = "Automatic" }
    @{ Name = "SysMain";                StartupType = "Automatic" }
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
    @{ Name = "RemoteRegistry";         StartupType = "Disabled" }
    @{ Name = "RemoteAccess";           StartupType = "Disabled" }
    @{ Name = "SessionEnv";             StartupType = "Manual" }
    @{ Name = "TermService";            StartupType = "Manual" }
    @{ Name = "UmRdpService";           StartupType = "Manual" }
    @{ Name = "RasMan";                 StartupType = "Manual" }
    @{ Name = "RasAuto";                StartupType = "Manual" }
    @{ Name = "SstpSvc";                StartupType = "Manual" }
    @{ Name = "Spooler";                StartupType = "Automatic" }
    @{ Name = "PrintNotify";            StartupType = "Manual" }
    @{ Name = "stisvc";                 StartupType = "Manual" }
    @{ Name = "Fax";                    StartupType = "Manual" }
    @{ Name = "TapiSrv";                StartupType = "Manual" }
    @{ Name = "WbioSrvc";               StartupType = "Manual" }
    @{ Name = "SensrSvc";               StartupType = "Manual" }
    @{ Name = "SensorDataService";      StartupType = "Manual" }
    @{ Name = "SensorService";          StartupType = "Manual" }
    @{ Name = "SCardSvr";               StartupType = "Manual" }
    @{ Name = "ScDeviceEnum";           StartupType = "Manual" }
    @{ Name = "SCPolicySvc";            StartupType = "Manual" }
    @{ Name = "WpcMonSvc";              StartupType = "Manual" }
    @{ Name = "bthserv";                StartupType = "Manual" }
    @{ Name = "BTAGService";            StartupType = "Manual" }
    @{ Name = "BthAvctpSvc";            StartupType = "Automatic" }
    @{ Name = "TabletInputService";     StartupType = "Manual" }
    @{ Name = "FrameServer";            StartupType = "Manual" }
    @{ Name = "wercplsupport";          StartupType = "Manual" }
    @{ Name = "WerSvc";                 StartupType = "Manual" }
    @{ Name = "seclogon";               StartupType = "Manual" }
    @{ Name = "CscService";             StartupType = "Automatic" }
    @{ Name = "HomeGroupListener";      StartupType = "Manual" }
    @{ Name = "HomeGroupProvider";      StartupType = "Manual" }
)

$restored = 0
$notFound = 0

Write-Log "Restoring services..." Cyan
Write-Log ""

foreach ($svc in $servicesToRestore) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($null -eq $service) {
        Write-Log "  [NOT FOUND] $($svc.Name)" DarkGray
        $notFound++
        continue
    }
    Set-Service -Name $svc.Name -StartupType $svc.StartupType
    Write-Log "  [RESTORED]  $($svc.Name) -> $($svc.StartupType)" Green
    $restored++
}

# ─────────────────────────────────────────────
# REVERT REGISTRY TWEAKS
# ─────────────────────────────────────────────
Write-Log ""
Write-Log "Reverting registry tweaks..." Cyan

$cortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
if (Test-Path $cortanaPath) {
    Remove-ItemProperty -Path $cortanaPath -Name "AllowCortana" -ErrorAction SilentlyContinue
    Write-Log "  [REG] Cortana policy removed" Green
}

$telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (Test-Path $telemetryPath) {
    Remove-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -ErrorAction SilentlyContinue
    Write-Log "  [REG] Telemetry policy removed" Green
}

$adPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
if (Test-Path $adPath) {
    Set-ItemProperty -Path $adPath -Name "Enabled" -Value 1 -Type DWord
    Write-Log "  [REG] Advertising ID re-enabled" Green
}

# ─────────────────────────────────────────────
# REVERT CPU TWEAKS
# ─────────────────────────────────────────────
Write-Log ""
Write-Log "Reverting CPU optimizations..." Cyan

$balancedGuid = (powercfg /list | Select-String "Balanced" | ForEach-Object {
    if ($_ -match "\(([0-9a-f-]{36})\)") { $Matches[1] }
})
if ($balancedGuid) {
    powercfg /setactive $balancedGuid | Out-Null
    Write-Log "  [POWER] Balanced power plan restored" Green
}

$visualFxPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
if (Test-Path $visualFxPath) {
    Set-ItemProperty -Path $visualFxPath -Name "VisualFXSetting" -Value 0 -Type DWord
    Write-Log "  [VISUAL] Visual effects reset to Windows default" Green
}

$explorerAdvPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $explorerAdvPath -Name "TaskbarAnimations" -Value 1 -Type DWord
Write-Log "  [VISUAL] Taskbar animations re-enabled" Green

$bgAppsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
if (Test-Path $bgAppsPath) {
    Set-ItemProperty -Path $bgAppsPath -Name "GlobalUserDisabled" -Value 0 -Type DWord
    Write-Log "  [BKGD] Background app access restored" Green
}

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
Write-Log "  [GAME] Game Bar and Game DVR restored" Green

$widgetPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (Test-Path $widgetPath) {
    Remove-ItemProperty -Path $widgetPath -Name "AllowNewsAndInterests" -ErrorAction SilentlyContinue
    Write-Log "  [WIDGET] Taskbar Widgets policy removed" Green
}

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
    -Name "Win32PrioritySeparation" -Value 2 -Type DWord
Write-Log "  [SCHED] Processor scheduling reset to Programs (default)" Green

# ─────────────────────────────────────────────
# REVERT v2 TWEAKS
# ─────────────────────────────────────────────
Write-Log ""
Write-Log "Reverting v2 tweaks..." Cyan

# Timeline / Activity History
$timelinePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (Test-Path $timelinePath) {
    Remove-ItemProperty -Path $timelinePath -Name "EnableActivityFeed"    -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $timelinePath -Name "PublishUserActivities" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $timelinePath -Name "UploadUserActivities"  -ErrorAction SilentlyContinue
    Write-Log "  [TIMELINE] Activity History policy removed" Green
}

# Telemetry scheduled tasks
$scheduledTasks = @(
    @{ Path = "\Microsoft\Windows\Application Experience\";                Name = "Microsoft Compatibility Appraiser" }
    @{ Path = "\Microsoft\Windows\Application Experience\";                Name = "ProgramDataUpdater" }
    @{ Path = "\Microsoft\Windows\Application Experience\";                Name = "StartupAppTask" }
    @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "Consolidator" }
    @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "UsbCeip" }
    @{ Path = "\Microsoft\Windows\DiskDiagnostic\";                        Name = "Microsoft-Windows-DiskDiagnosticDataCollector" }
    @{ Path = "\Microsoft\Windows\Feedback\Siuf\";                         Name = "DmClient" }
    @{ Path = "\Microsoft\Windows\Feedback\Siuf\";                         Name = "DmClientOnScenarioDownload" }
    @{ Path = "\Microsoft\Windows\Windows Error Reporting\";               Name = "QueueReporting" }
    @{ Path = "\Microsoft\Windows\Autochk\";                               Name = "Proxy" }
    @{ Path = "\Microsoft\Windows\CloudExperienceHost\";                   Name = "CreateObjectTask" }
    @{ Path = "\Microsoft\Windows\DiskFootprint\";                         Name = "Diagnostics" }
    @{ Path = "\Microsoft\Windows\Maps\";                                  Name = "MapsToastTask" }
    @{ Path = "\Microsoft\Windows\Maps\";                                  Name = "MapsUpdateTask" }
    @{ Path = "\Microsoft\Windows\NetTrace\";                              Name = "GatherNetworkInfo" }
    @{ Path = "\Microsoft\Windows\WDI\";                                   Name = "ResolutionHost" }
    @{ Path = "\Microsoft\Windows\Power Efficiency Diagnostics\";          Name = "AnalyzeSystem" }
    @{ Path = "\Microsoft\Windows\Maintenance\";                           Name = "WinSAT" }
)
$tasksRestored = 0
foreach ($task in $scheduledTasks) {
    $t = Get-ScheduledTask -TaskPath $task.Path -TaskName $task.Name -ErrorAction SilentlyContinue
    if ($null -ne $t) {
        Enable-ScheduledTask -TaskPath $task.Path -TaskName $task.Name -ErrorAction SilentlyContinue | Out-Null
        $tasksRestored++
    }
}
Write-Log "  [TASKS] $tasksRestored scheduled tasks re-enabled" Green

# Fast Startup
$fastStartupPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
if (Test-Path $fastStartupPath) {
    Set-ItemProperty -Path $fastStartupPath -Name "HiberbootEnabled" -Value 1 -Type DWord
    Write-Log "  [BOOT] Fast Startup re-enabled" Green
}

# Automatic Maintenance
$maintPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance"
if (Test-Path $maintPath) {
    Remove-ItemProperty -Path $maintPath -Name "MaintenanceDisabled" -ErrorAction SilentlyContinue
    Write-Log "  [MAINT] Automatic Maintenance re-enabled" Green
}

# Window transparency
$themePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
if (Test-Path $themePath) {
    Set-ItemProperty -Path $themePath -Name "EnableTransparency" -Value 1 -Type DWord
    Write-Log "  [VISUAL] Window transparency re-enabled" Green
}

# Snap Assist
Set-ItemProperty -Path $explorerAdvPath -Name "SnapAssist"       -Value 1 -Type DWord
Set-ItemProperty -Path $explorerAdvPath -Name "EnableSnapBar"    -Value 1 -Type DWord
Set-ItemProperty -Path $explorerAdvPath -Name "EnableTaskGroups" -Value 1 -Type DWord
Write-Log "  [SNAP] Snap Assist re-enabled" Green

# Window shadows
Set-ItemProperty -Path $explorerAdvPath -Name "ListviewShadow" -Value 1 -Type DWord
Write-Log "  [VISUAL] Window shadows re-enabled" Green

# HAGS
$graphicsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
if (Test-Path $graphicsPath) {
    Set-ItemProperty -Path $graphicsPath -Name "HwSchMode" -Value 1 -Type DWord
    Write-Log "  [GPU] HAGS disabled (restored to default)" Green
}

# DWM / Multimedia profile
$mmProfilePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (Test-Path $mmProfilePath) {
    Set-ItemProperty -Path $mmProfilePath -Name "SystemResponsiveness"   -Value 20         -Type DWord
    Set-ItemProperty -Path $mmProfilePath -Name "NetworkThrottlingIndex" -Value 10         -Type DWord
    Write-Log "  [DWM] Multimedia system profile restored to defaults" Green
}

# Network Auto-Tuning
netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
Write-Log "  [NET] TCP Auto-Tuning restored to normal" Green

# IPv6
Get-NetAdapter | ForEach-Object {
    Enable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
}
$tcpip6Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
if (Test-Path $tcpip6Path) {
    Remove-ItemProperty -Path $tcpip6Path -Name "DisabledComponents" -ErrorAction SilentlyContinue
}
Write-Log "  [NET] IPv6 re-enabled on all adapters" Green

# QoS
$qosPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
if (Test-Path $qosPath) {
    Remove-ItemProperty -Path $qosPath -Name "NonBestEffortLimit" -ErrorAction SilentlyContinue
    Write-Log "  [NET] QoS bandwidth reservation restored to default" Green
}

# NTFS Last Access Time
fsutil behavior set disablelastaccess 0 | Out-Null
Write-Log "  [NTFS] Last Access Time re-enabled" Green

# NTFS 8.3
fsutil behavior set disable8dot3 0 | Out-Null
Write-Log "  [NTFS] 8.3 filename generation re-enabled" Green

# Startup delay
$startupDelayPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
if (Test-Path $startupDelayPath) {
    Remove-ItemProperty -Path $startupDelayPath -Name "StartupDelayInMSec" -ErrorAction SilentlyContinue
    Write-Log "  [BOOT] Startup app delay restored to default" Green
}

# ─────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────
Write-Log ""
Write-Log "============================================" Cyan
Write-Log "  RESTORE COMPLETE" Cyan
Write-Log "============================================" Cyan
Write-Log ""
Write-Log "  Services restored   : $restored"   Green
Write-Log "  Services not found  : $notFound"   DarkGray
Write-Log ""
Write-Log "  NOTE: Removed apps cannot be restored via this script." Yellow
Write-Log "  Use the Microsoft Store or System Restore to recover them." Yellow
Write-Log ""
Write-Log "  REBOOT RECOMMENDED to apply all changes." Cyan
Write-Log "============================================" Cyan
Write-Log ""

# ─────────────────────────────────────────────
# SAVE HTML LOG
# ─────────────────────────────────────────────
Save-HtmlLog
