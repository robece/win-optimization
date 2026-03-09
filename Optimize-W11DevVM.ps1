#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 VM optimization script for corporate development environments.
    - Disables unnecessary background services
    - Removes bloatware / non-productivity apps
    - Applies CPU and visual performance tweaks
    Preserves Office 365, Teams, OneDrive, and general dev tooling.

.NOTES
    Run as Administrator. Creates a restore point before making changes.
    To revert changes run: Restore-W11DevVM.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# ─────────────────────────────────────────────
# SNAPSHOT: RAM + CPU before
# ─────────────────────────────────────────────
$memBefore    = Get-CimInstance -ClassName Win32_OperatingSystem
$freeBeforeMB = [math]::Round($memBefore.FreePhysicalMemory / 1024, 2)
$totalMB      = [math]::Round($memBefore.TotalVisibleMemorySize / 1024, 2)
$usedBeforeMB = $totalMB - $freeBeforeMB
$cpuBefore    = [math]::Round((Get-CimInstance -ClassName Win32_Processor |
                    Measure-Object -Property LoadPercentage -Average).Average, 1)

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  W11 Dev VM Optimizer  (RAM + CPU + Apps)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[BEFORE] Total RAM : $totalMB MB" -ForegroundColor Yellow
Write-Host "[BEFORE] Used RAM  : $usedBeforeMB MB  |  Free: $freeBeforeMB MB" -ForegroundColor Yellow
Write-Host "[BEFORE] CPU Load  : $cpuBefore %" -ForegroundColor Yellow
Write-Host ""

# ─────────────────────────────────────────────
# CREATE RESTORE POINT
# ─────────────────────────────────────────────
Write-Host "Creating system restore point..." -ForegroundColor Gray
Enable-ComputerRestore -Drive "C:\" | Out-Null
Checkpoint-Computer -Description "Before W11 VM Optimization" -RestorePointType "MODIFY_SETTINGS" | Out-Null
Write-Host "Restore point created." -ForegroundColor Green
Write-Host ""

# ─────────────────────────────────────────────
# BLOATWARE APPS TO REMOVE
# Apps are removed for the current user.
# Provisioned packages are removed so they don't
# reinstall on new user accounts.
# PRESERVED: Office, Teams, OneDrive, Notepad,
#            Calculator, Paint, Snipping Tool,
#            Windows Terminal
# ─────────────────────────────────────────────
$appsToRemove = @(
    # ── Gaming ────────────────────────────────
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.Xbox.TCUI"
    "Microsoft.GamingApp"
    "Microsoft.XboxGameCallableUI"

    # ── Entertainment / media ─────────────────
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.MixedReality.Portal"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.Print3D"
    "Microsoft.3DBuilder"

    # ── Social / communication (non-Teams) ────
    "Microsoft.SkypeApp"
    "Microsoft.People"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.BingNews"
    "Microsoft.BingWeather"
    "Microsoft.BingFinance"
    "Microsoft.BingSports"
    "Microsoft.BingTranslator"

    # ── Consumer / retail apps ────────────────
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

    # ── Non-essential Microsoft apps ──────────
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

    # ── Mixed reality ─────────────────────────
    "Microsoft.Whiteboard"
    "Microsoft.HoloCamera"
    "Microsoft.HoloItemPlayerApp"
    "Microsoft.HoloShell"
)

Write-Host "Removing bloatware apps..." -ForegroundColor Cyan
Write-Host ""

$appsRemoved  = 0
$appsNotFound = 0

foreach ($app in $appsToRemove) {
    $pkg         = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                   Where-Object { $_.DisplayName -eq $app }

    if ($null -eq $pkg -and $null -eq $provisioned) {
        Write-Host "  [NOT FOUND]  $app" -ForegroundColor DarkGray
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

    Write-Host "  [REMOVED]    $app" -ForegroundColor Green
    $appsRemoved++
}

# ─────────────────────────────────────────────
# SERVICES TO DISABLE
# ─────────────────────────────────────────────
$servicesToDisable = @(

    # ── Telemetry & diagnostics ──────────────────
    @{ Name = "DiagTrack";              Reason = "Connected User Experiences / telemetry" }
    @{ Name = "dmwappushservice";       Reason = "WAP Push message routing (telemetry)" }
    @{ Name = "PcaSvc";                 Reason = "Program Compatibility Assistant" }
    @{ Name = "DPS";                    Reason = "Diagnostic Policy Service" }
    @{ Name = "WdiServiceHost";         Reason = "Diagnostic Service Host" }
    @{ Name = "WdiSystemHost";          Reason = "Diagnostic System Host" }

    # ── Search indexing ───────────────────────────
    @{ Name = "WSearch";                Reason = "Windows Search indexing (high background CPU/IO)" }

    # ── Superfetch / SysMain ──────────────────────
    @{ Name = "SysMain";                Reason = "Superfetch — prefetches apps using CPU cycles" }

    # ── Consumer / retail / gaming features ──────
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

    # ── Remote / assistance features ─────────────
    @{ Name = "RemoteRegistry";         Reason = "Remote Registry access" }
    @{ Name = "RemoteAccess";           Reason = "Routing and Remote Access" }
    @{ Name = "SessionEnv";             Reason = "Remote Desktop Configuration" }
    @{ Name = "TermService";            Reason = "Remote Desktop Services (inbound RDP)" }
    @{ Name = "UmRdpService";           Reason = "Remote Desktop Device Redirector" }
    @{ Name = "RasMan";                 Reason = "Remote Access Connection Manager" }
    @{ Name = "RasAuto";                Reason = "Remote Access AutoDial Manager" }
    @{ Name = "SstpSvc";                Reason = "Secure Socket Tunneling Protocol" }

    # ── Printing & scanning ───────────────────────
    @{ Name = "Spooler";                Reason = "Print Spooler (no physical printer in VM)" }
    @{ Name = "PrintNotify";            Reason = "Printer Extensions and Notifications" }
    @{ Name = "stisvc";                 Reason = "Windows Image Acquisition (scanner)" }

    # ── Fax / telephony ───────────────────────────
    @{ Name = "Fax";                    Reason = "Fax service" }
    @{ Name = "TapiSrv";                Reason = "Telephony" }

    # ── Biometrics / sensors ──────────────────────
    @{ Name = "WbioSrvc";               Reason = "Windows Biometric Service" }
    @{ Name = "SensrSvc";               Reason = "Sensor Monitoring Service" }
    @{ Name = "SensorDataService";      Reason = "Sensor Data Service" }
    @{ Name = "SensorService";          Reason = "Sensor Service" }

    # ── Smart card ────────────────────────────────
    @{ Name = "SCardSvr";               Reason = "Smart Card" }
    @{ Name = "ScDeviceEnum";           Reason = "Smart Card Device Enumeration" }
    @{ Name = "SCPolicySvc";            Reason = "Smart Card Removal Policy" }

    # ── Parental controls ─────────────────────────
    @{ Name = "WpcMonSvc";              Reason = "Parental Controls" }

    # ── Bluetooth (no BT hardware in VM) ──────────
    @{ Name = "bthserv";                Reason = "Bluetooth Support Service" }
    @{ Name = "BTAGService";            Reason = "Bluetooth Audio Gateway" }
    @{ Name = "BthAvctpSvc";            Reason = "Bluetooth AVCTP" }

    # ── Tablet / touch / camera (VM) ─────────────
    @{ Name = "TabletInputService";     Reason = "Touch Keyboard and Handwriting" }
    @{ Name = "FrameServer";            Reason = "Windows Camera Frame Server" }

    # ── Error reporting ───────────────────────────
    @{ Name = "wercplsupport";          Reason = "Problem Reports Control Panel Support" }
    @{ Name = "WerSvc";                 Reason = "Windows Error Reporting" }

    # ── Secondary logon ───────────────────────────
    @{ Name = "seclogon";               Reason = "Secondary Logon" }

    # ── Offline files ─────────────────────────────
    @{ Name = "CscService";             Reason = "Offline Files" }

    # ── HomeGroup (legacy) ────────────────────────
    @{ Name = "HomeGroupListener";      Reason = "HomeGroup Listener (legacy)" }
    @{ Name = "HomeGroupProvider";      Reason = "HomeGroup Provider (legacy)" }
)

$disabled = 0
$skipped  = 0
$notFound = 0

Write-Host ""
Write-Host "Disabling services..." -ForegroundColor Cyan
Write-Host ""

foreach ($svc in $servicesToDisable) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($null -eq $service) {
        Write-Host "  [NOT FOUND]        $($svc.Name)" -ForegroundColor DarkGray
        $notFound++
        continue
    }

    if ($service.StartType -eq "Disabled") {
        Write-Host "  [ALREADY DISABLED] $($svc.Name)" -ForegroundColor DarkGray
        $skipped++
        continue
    }

    if ($service.Status -eq "Running") {
        Stop-Service -Name $svc.Name -Force -NoWait
    }

    Set-Service -Name $svc.Name -StartupType Disabled
    Write-Host "  [DISABLED] $($svc.Name) — $($svc.Reason)" -ForegroundColor Green
    $disabled++
}

# ─────────────────────────────────────────────
# REGISTRY TWEAKS
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Applying registry tweaks..." -ForegroundColor Cyan

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
    Write-Host "  [REG] $($tweak.Reason)" -ForegroundColor Green
}

# ─────────────────────────────────────────────
# CPU OPTIMIZATIONS
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Applying CPU optimizations..." -ForegroundColor Cyan

# 1. Power plan: High Performance
Write-Host "  [POWER] Setting power plan to High Performance..." -ForegroundColor Green
$hpGuid = (powercfg /list | Select-String "High performance" | ForEach-Object {
    if ($_ -match "\(([0-9a-f-]{36})\)") { $Matches[1] }
})
if ($hpGuid) {
    powercfg /setactive $hpGuid | Out-Null
    Write-Host "  [POWER] High Performance plan activated (GUID: $hpGuid)" -ForegroundColor Green
} else {
    powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
    $hpGuid = (powercfg /list | Select-String "High performance" | ForEach-Object {
        if ($_ -match "\(([0-9a-f-]{36})\)") { $Matches[1] }
    })
    if ($hpGuid) { powercfg /setactive $hpGuid | Out-Null }
    Write-Host "  [POWER] High Performance plan created and activated." -ForegroundColor Green
}

# 2. Disable visual effects
Write-Host "  [VISUAL] Disabling animations and visual effects..." -ForegroundColor Green
$visualFxPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
if (-not (Test-Path $visualFxPath)) { New-Item -Path $visualFxPath -Force | Out-Null }
Set-ItemProperty -Path $visualFxPath -Name "VisualFXSetting" -Value 2 -Type DWord

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

# 3. Disable background UWP apps
Write-Host "  [BKGD] Disabling background app access..." -ForegroundColor Green
$bgAppsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
if (-not (Test-Path $bgAppsPath)) { New-Item -Path $bgAppsPath -Force | Out-Null }
Set-ItemProperty -Path $bgAppsPath -Name "GlobalUserDisabled" -Value 1 -Type DWord

# 4. Disable Game Bar and Game DVR
Write-Host "  [GAME] Disabling Game Bar and Game DVR..." -ForegroundColor Green
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

# 5. Disable Taskbar Widgets
Write-Host "  [WIDGET] Disabling Taskbar Widgets..." -ForegroundColor Green
$widgetPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (-not (Test-Path $widgetPath)) { New-Item -Path $widgetPath -Force | Out-Null }
Set-ItemProperty -Path $widgetPath -Name "AllowNewsAndInterests" -Value 0 -Type DWord

# 6. Processor scheduling: Background Services
Write-Host "  [SCHED] Setting processor scheduling to Background Services..." -ForegroundColor Green
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
    -Name "Win32PrioritySeparation" -Value 24 -Type DWord

Write-Host ""

# ─────────────────────────────────────────────
# SNAPSHOT: RAM + CPU after
# ─────────────────────────────────────────────
Write-Host "Waiting 8 seconds for changes to settle..." -ForegroundColor Gray
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
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RESULTS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Apps removed        : $appsRemoved"                -ForegroundColor Green
Write-Host "  Apps not found      : $appsNotFound"               -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Services processed  : $($servicesToDisable.Count)" -ForegroundColor White
Write-Host "  Newly disabled      : $disabled"                   -ForegroundColor Green
Write-Host "  Already disabled    : $skipped"                    -ForegroundColor DarkGray
Write-Host "  Not found on system : $notFound"                   -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Total RAM           : $totalMB MB"                 -ForegroundColor White
Write-Host ""
Write-Host "  [BEFORE] Used RAM   : $usedBeforeMB MB  |  Free: $freeBeforeMB MB" -ForegroundColor Yellow
Write-Host "  [AFTER]  Used RAM   : $usedAfterMB MB  |  Free: $freeAfterMB MB"   -ForegroundColor Green

if ($savedMB -gt 0) {
    Write-Host "  RAM freed           : +$savedMB MB ($savedPct% of total)"       -ForegroundColor Green
} else {
    Write-Host "  RAM freed           : $savedMB MB (reboot to see full effect)"   -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "  [BEFORE] CPU Load   : $cpuBefore %"               -ForegroundColor Yellow
Write-Host "  [AFTER]  CPU Load   : $cpuAfter %"                -ForegroundColor Green

if ($cpuDiff -gt 0) {
    Write-Host "  CPU reduction       : -$cpuDiff %"             -ForegroundColor Green
} elseif ($cpuDiff -lt 0) {
    Write-Host "  CPU delta           : $cpuDiff % (snapshot variance, reboot to confirm)" -ForegroundColor DarkYellow
} else {
    Write-Host "  CPU delta           : no change in snapshot (reboot to see full effect)"  -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  CPU optimizations applied:" -ForegroundColor White
Write-Host "    - Power plan set to High Performance"            -ForegroundColor Green
Write-Host "    - Visual effects disabled (best performance)"    -ForegroundColor Green
Write-Host "    - Background UWP apps disabled"                  -ForegroundColor Green
Write-Host "    - Game Bar and Game DVR disabled"                -ForegroundColor Green
Write-Host "    - Taskbar Widgets disabled"                      -ForegroundColor Green
Write-Host "    - Processor scheduling: Background Services"     -ForegroundColor Green
Write-Host ""
Write-Host "  A restore point was created before any changes."   -ForegroundColor Cyan
Write-Host "  REBOOT RECOMMENDED to fully apply all changes."    -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
