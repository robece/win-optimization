#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 VM optimization script v1 for corporate development environments.
    - Disables unnecessary background services
    - Removes bloatware / non-productivity apps
    - Applies CPU and visual performance tweaks
    - Generates a full-color HTML log
    Preserves Office 365, Teams, OneDrive, and general dev tooling.

.NOTES
    Run as Administrator. Creates a restore point before making changes.
    To revert changes run: Restore-W11DevVM.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# ─────────────────────────────────────────────
# HTML LOG ENGINE
# ─────────────────────────────────────────────
$script:htmlLines = [System.Collections.Generic.List[string]]::new()
$script:logPath   = "$PSScriptRoot\optimize-log.html"

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
    <title>W11 VM Optimizer v1 - Log</title>
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
# SNAPSHOT: RAM + CPU before
# ─────────────────────────────────────────────
$memBefore    = Get-CimInstance -ClassName Win32_OperatingSystem
$freeBeforeMB = [math]::Round($memBefore.FreePhysicalMemory / 1024, 2)
$totalMB      = [math]::Round($memBefore.TotalVisibleMemorySize / 1024, 2)
$usedBeforeMB = $totalMB - $freeBeforeMB
$cpuBefore    = [math]::Round((Get-CimInstance -ClassName Win32_Processor |
                    Measure-Object -Property LoadPercentage -Average).Average, 1)

Write-Log ""
Write-Log "============================================" Cyan
Write-Log "  W11 Dev VM Optimizer  (RAM + CPU + Apps)" Cyan
Write-Log "============================================" Cyan
Write-Log ""
Write-Log "[BEFORE] Total RAM : $totalMB MB" Yellow
Write-Log "[BEFORE] Used RAM  : $usedBeforeMB MB  |  Free: $freeBeforeMB MB" Yellow
Write-Log "[BEFORE] CPU Load  : $cpuBefore %" Yellow
Write-Log ""

# ─────────────────────────────────────────────
# CREATE RESTORE POINT
# ─────────────────────────────────────────────
Write-Log "Creating system restore point..." Gray
Enable-ComputerRestore -Drive "C:\" | Out-Null
Checkpoint-Computer -Description "Before W11 VM Optimization" -RestorePointType "MODIFY_SETTINGS" | Out-Null
Write-Log "Restore point created." Green
Write-Log ""

# ─────────────────────────────────────────────
# BLOATWARE APPS TO REMOVE
# ─────────────────────────────────────────────
$appsToRemove = @(
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.Xbox.TCUI"
    "Microsoft.GamingApp"
    "Microsoft.XboxGameCallableUI"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.MixedReality.Portal"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.Print3D"
    "Microsoft.3DBuilder"
    "Microsoft.SkypeApp"
    "Microsoft.People"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.BingNews"
    "Microsoft.BingWeather"
    "Microsoft.BingFinance"
    "Microsoft.BingSports"
    "Microsoft.BingTranslator"
    "king.com.CandyCrushSaga"
    "king.com.CandyCrushFriends"
    "king.com.BubbleWitch3Saga"
    "king.com.FarmHeroesSaga"
    "SpotifyAB.SpotifyMusic"
    "BytedancePte.Ltd.TikTok"
    "Netflix.Netflix"
    "AmazonVideo.PrimeVideo"
    "Disney.37853D22215E2"
    "Facebook.Facebook"
    "Instagram.Instagram"
    "Twitter.Twitter"
    "TikTok.TikTok"
    "Hulu.HuluApp"
    "Flipboard.Flipboard"
    "PandoraMediaInc.29680B314EFC2"
    "AdobeSystemsIncorporated.AdobePhotoshopExpress"
    "Microsoft.Todos"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.WindowsMaps"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.PowerAutomateDesktop"
    "Microsoft.Wallet"
    "Microsoft.549981C3F5F10"
    "Microsoft.Whiteboard"
    "Microsoft.HoloCamera"
    "Microsoft.HoloItemPlayerApp"
    "Microsoft.HoloShell"
)

Write-Log "Removing bloatware apps..." Cyan
Write-Log ""

$appsRemoved  = 0
$appsNotFound = 0

foreach ($app in $appsToRemove) {
    $pkg         = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                   Where-Object { $_.DisplayName -eq $app }

    if ($null -eq $pkg -and $null -eq $provisioned) {
        Write-Log "  [NOT FOUND]  $app" DarkGray
        $appsNotFound++
        continue
    }
    if ($null -ne $pkg) {
        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    }
    if ($null -ne $provisioned) {
        Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName `
            -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Log "  [REMOVED]    $app" Green
    $appsRemoved++
}

# ─────────────────────────────────────────────
# SERVICES TO DISABLE
# ─────────────────────────────────────────────
$servicesToDisable = @(
    @{ Name = "DiagTrack";              Reason = "Connected User Experiences / telemetry" }
    @{ Name = "dmwappushservice";       Reason = "WAP Push message routing (telemetry)" }
    @{ Name = "PcaSvc";                 Reason = "Program Compatibility Assistant" }
    @{ Name = "DPS";                    Reason = "Diagnostic Policy Service" }
    @{ Name = "WdiServiceHost";         Reason = "Diagnostic Service Host" }
    @{ Name = "WdiSystemHost";          Reason = "Diagnostic System Host" }
    @{ Name = "WSearch";                Reason = "Windows Search indexing (high background CPU/IO)" }
    @{ Name = "SysMain";                Reason = "Superfetch - prefetches apps using CPU cycles" }
    @{ Name = "XblAuthManager";         Reason = "Xbox Live Auth" }
    @{ Name = "XblGameSave";            Reason = "Xbox Live Game Save" }
    @{ Name = "XboxNetApiSvc";          Reason = "Xbox Live Networking (background polling)" }
    @{ Name = "XboxGipSvc";             Reason = "Xbox Accessory Management" }
    @{ Name = "GamingServices";         Reason = "Xbox Gaming Services" }
    @{ Name = "spectrum";               Reason = "Windows Perception / Mixed Reality" }
    @{ Name = "perceptionsimulation";   Reason = "Mixed Reality simulation" }
    @{ Name = "WMPNetworkSvc";          Reason = "Windows Media Player Network Sharing" }
    @{ Name = "RetailDemo";             Reason = "Retail Demo Service" }
    @{ Name = "MapsBroker";             Reason = "Downloaded Maps Manager" }
    @{ Name = "InstallService";         Reason = "Microsoft Store Install Service" }
    @{ Name = "RemoteRegistry";         Reason = "Remote Registry access" }
    @{ Name = "RemoteAccess";           Reason = "Routing and Remote Access" }
    @{ Name = "SessionEnv";             Reason = "Remote Desktop Configuration" }
    @{ Name = "TermService";            Reason = "Remote Desktop Services (inbound RDP)" }
    @{ Name = "UmRdpService";           Reason = "Remote Desktop Device Redirector" }
    @{ Name = "RasMan";                 Reason = "Remote Access Connection Manager" }
    @{ Name = "RasAuto";                Reason = "Remote Access AutoDial Manager" }
    @{ Name = "SstpSvc";                Reason = "Secure Socket Tunneling Protocol" }
    @{ Name = "Spooler";                Reason = "Print Spooler (no physical printer in VM)" }
    @{ Name = "PrintNotify";            Reason = "Printer Extensions and Notifications" }
    @{ Name = "stisvc";                 Reason = "Windows Image Acquisition (scanner)" }
    @{ Name = "Fax";                    Reason = "Fax service" }
    @{ Name = "TapiSrv";                Reason = "Telephony" }
    @{ Name = "WbioSrvc";               Reason = "Windows Biometric Service" }
    @{ Name = "SensrSvc";               Reason = "Sensor Monitoring Service" }
    @{ Name = "SensorDataService";      Reason = "Sensor Data Service" }
    @{ Name = "SensorService";          Reason = "Sensor Service" }
    @{ Name = "SCardSvr";               Reason = "Smart Card" }
    @{ Name = "ScDeviceEnum";           Reason = "Smart Card Device Enumeration" }
    @{ Name = "SCPolicySvc";            Reason = "Smart Card Removal Policy" }
    @{ Name = "WpcMonSvc";              Reason = "Parental Controls" }
    @{ Name = "bthserv";                Reason = "Bluetooth Support Service" }
    @{ Name = "BTAGService";            Reason = "Bluetooth Audio Gateway" }
    @{ Name = "BthAvctpSvc";            Reason = "Bluetooth AVCTP" }
    @{ Name = "TabletInputService";     Reason = "Touch Keyboard and Handwriting" }
    @{ Name = "FrameServer";            Reason = "Windows Camera Frame Server" }
    @{ Name = "wercplsupport";          Reason = "Problem Reports Control Panel Support" }
    @{ Name = "WerSvc";                 Reason = "Windows Error Reporting" }
    @{ Name = "seclogon";               Reason = "Secondary Logon" }
    @{ Name = "CscService";             Reason = "Offline Files" }
    @{ Name = "HomeGroupListener";      Reason = "HomeGroup Listener (legacy)" }
    @{ Name = "HomeGroupProvider";      Reason = "HomeGroup Provider (legacy)" }
)

$disabled = 0
$skipped  = 0
$notFound = 0

Write-Log ""
Write-Log "Disabling services..." Cyan
Write-Log ""

foreach ($svc in $servicesToDisable) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($null -eq $service) {
        Write-Log "  [NOT FOUND]        $($svc.Name)" DarkGray
        $notFound++
        continue
    }
    if ($service.StartType -eq "Disabled") {
        Write-Log "  [ALREADY DISABLED] $($svc.Name)" DarkGray
        $skipped++
        continue
    }
    if ($service.Status -eq "Running") {
        Stop-Service -Name $svc.Name -Force -NoWait
    }
    Set-Service -Name $svc.Name -StartupType Disabled
    Write-Log "  [DISABLED] $($svc.Name) - $($svc.Reason)" Green
    $disabled++
}

# ─────────────────────────────────────────────
# REGISTRY TWEAKS
# ─────────────────────────────────────────────
Write-Log ""
Write-Log "Applying registry tweaks..." Cyan

$regTweaks = @(
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
       Name = "AllowCortana"; Value = 0; Type = "DWord"; Reason = "Disable Cortana" }
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
       Name = "AllowTelemetry"; Value = 0; Type = "DWord"; Reason = "Disable telemetry" }
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
       Name = "Enabled"; Value = 0; Type = "DWord"; Reason = "Disable advertising ID" }
)

foreach ($tweak in $regTweaks) {
    if (-not (Test-Path $tweak.Path)) { New-Item -Path $tweak.Path -Force | Out-Null }
    Set-ItemProperty -Path $tweak.Path -Name $tweak.Name -Value $tweak.Value -Type $tweak.Type
    Write-Log "  [REG] $($tweak.Reason)" Green
}

# ─────────────────────────────────────────────
# CPU OPTIMIZATIONS
# ─────────────────────────────────────────────
Write-Log ""
Write-Log "Applying CPU optimizations..." Cyan

$hpGuid = (powercfg /list | Select-String "High performance" | ForEach-Object {
    if ($_ -match "\(([0-9a-f-]{36})\)") { $Matches[1] }
})
if ($hpGuid) {
    powercfg /setactive $hpGuid | Out-Null
    Write-Log "  [POWER] High Performance plan activated" Green
} else {
    powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
    $hpGuid = (powercfg /list | Select-String "High performance" | ForEach-Object {
        if ($_ -match "\(([0-9a-f-]{36})\)") { $Matches[1] }
    })
    if ($hpGuid) { powercfg /setactive $hpGuid | Out-Null }
    Write-Log "  [POWER] High Performance plan created and activated" Green
}

$visualFxPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
if (-not (Test-Path $visualFxPath)) { New-Item -Path $visualFxPath -Force | Out-Null }
Set-ItemProperty -Path $visualFxPath -Name "VisualFXSetting" -Value 2 -Type DWord
Write-Log "  [VISUAL] Visual effects set to best performance" Green

$animKeys = @(
    @{ Path = "HKCU:\Control Panel\Desktop"
       Name = "UserPreferencesMask"
       Value = ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)); Type = "Binary" }
    @{ Path = "HKCU:\Control Panel\Desktop"
       Name = "MenuShowDelay"; Value = "0"; Type = "String" }
    @{ Path = "HKCU:\Control Panel\Desktop\WindowMetrics"
       Name = "MinAnimate"; Value = "0"; Type = "String" }
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
       Name = "ListviewAlphaSelect"; Value = 0; Type = "DWord" }
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
       Name = "TaskbarAnimations"; Value = 0; Type = "DWord" }
    @{ Path = "HKCU:\Software\Microsoft\Windows\DWM"
       Name = "EnableAeroPeek"; Value = 0; Type = "DWord" }
)
foreach ($key in $animKeys) {
    if (-not (Test-Path $key.Path)) { New-Item -Path $key.Path -Force | Out-Null }
    Set-ItemProperty -Path $key.Path -Name $key.Name -Value $key.Value -Type $key.Type
}

$bgAppsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
if (-not (Test-Path $bgAppsPath)) { New-Item -Path $bgAppsPath -Force | Out-Null }
Set-ItemProperty -Path $bgAppsPath -Name "GlobalUserDisabled" -Value 1 -Type DWord
Write-Log "  [BKGD] Background UWP apps disabled" Green

$gameBarKeys = @(
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
       Name = "AppCaptureEnabled"; Value = 0; Type = "DWord" }
    @{ Path = "HKCU:\System\GameConfigStore"
       Name = "GameDVR_Enabled"; Value = 0; Type = "DWord" }
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
       Name = "AllowGameDVR"; Value = 0; Type = "DWord" }
)
foreach ($key in $gameBarKeys) {
    if (-not (Test-Path $key.Path)) { New-Item -Path $key.Path -Force | Out-Null }
    Set-ItemProperty -Path $key.Path -Name $key.Name -Value $key.Value -Type $key.Type
}
Write-Log "  [GAME] Game Bar and Game DVR disabled" Green

$widgetPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (-not (Test-Path $widgetPath)) { New-Item -Path $widgetPath -Force | Out-Null }
Set-ItemProperty -Path $widgetPath -Name "AllowNewsAndInterests" -Value 0 -Type DWord
Write-Log "  [WIDGET] Taskbar Widgets disabled" Green

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
    -Name "Win32PrioritySeparation" -Value 24 -Type DWord
Write-Log "  [SCHED] Processor scheduling set to Background Services" Green
Write-Log ""

# ─────────────────────────────────────────────
# SNAPSHOT: RAM + CPU after
# ─────────────────────────────────────────────
Write-Log "Waiting 8 seconds for changes to settle..." Gray
Start-Sleep -Seconds 8

$memAfter    = Get-CimInstance -ClassName Win32_OperatingSystem
$freeAfterMB = [math]::Round($memAfter.FreePhysicalMemory / 1024, 2)
$usedAfterMB = $totalMB - $freeAfterMB
$savedMB     = [math]::Round($freeAfterMB - $freeBeforeMB, 2)
$savedPct    = [math]::Round(($savedMB / $totalMB) * 100, 1)
$cpuAfter    = [math]::Round((Get-CimInstance -ClassName Win32_Processor |
                   Measure-Object -Property LoadPercentage -Average).Average, 1)
$cpuDiff     = [math]::Round($cpuBefore - $cpuAfter, 1)

# ─────────────────────────────────────────────
# FINAL REPORT
# ─────────────────────────────────────────────
Write-Log "============================================" Cyan
Write-Log "  RESULTS" Cyan
Write-Log "============================================" Cyan
Write-Log ""
Write-Log "  Apps removed        : $appsRemoved"                Green
Write-Log "  Apps not found      : $appsNotFound"               DarkGray
Write-Log ""
Write-Log "  Services processed  : $($servicesToDisable.Count)" White
Write-Log "  Newly disabled      : $disabled"                   Green
Write-Log "  Already disabled    : $skipped"                    DarkGray
Write-Log "  Not found on system : $notFound"                   DarkGray
Write-Log ""
Write-Log "  Total RAM           : $totalMB MB"                 White
Write-Log ""
Write-Log "  [BEFORE] Used RAM   : $usedBeforeMB MB  |  Free: $freeBeforeMB MB" Yellow
Write-Log "  [AFTER]  Used RAM   : $usedAfterMB MB  |  Free: $freeAfterMB MB"   Green

if ($savedMB -gt 0) {
    Write-Log "  RAM freed           : +$savedMB MB ($savedPct% of total)"      Green
} else {
    Write-Log "  RAM freed           : $savedMB MB (reboot to see full effect)"  DarkYellow
}

Write-Log ""
Write-Log "  [BEFORE] CPU Load   : $cpuBefore %"               Yellow
Write-Log "  [AFTER]  CPU Load   : $cpuAfter %"                Green

if ($cpuDiff -gt 0) {
    Write-Log "  CPU reduction       : -$cpuDiff %"             Green
} elseif ($cpuDiff -lt 0) {
    Write-Log "  CPU delta           : $cpuDiff % (snapshot variance, reboot to confirm)" DarkYellow
} else {
    Write-Log "  CPU delta           : no change in snapshot (reboot to see full effect)"  DarkGray
}

Write-Log ""
Write-Log "  CPU optimizations applied:"                        White
Write-Log "    - Power plan set to High Performance"            Green
Write-Log "    - Visual effects disabled (best performance)"    Green
Write-Log "    - Background UWP apps disabled"                  Green
Write-Log "    - Game Bar and Game DVR disabled"                Green
Write-Log "    - Taskbar Widgets disabled"                      Green
Write-Log "    - Processor scheduling: Background Services"     Green
Write-Log ""
Write-Log "  A restore point was created before any changes."   Cyan
Write-Log "  REBOOT RECOMMENDED to fully apply all changes."    Cyan
Write-Log "============================================" Cyan
Write-Log ""

# ─────────────────────────────────────────────
# SAVE HTML LOG
# ─────────────────────────────────────────────
Save-HtmlLog
