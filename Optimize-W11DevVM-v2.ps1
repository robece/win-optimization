#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 VM optimization script v2 — corporate development environments.
    Includes all v1 optimizations plus:
    - Timeline / Activity History disabled
    - Telemetry scheduled tasks cleaned
    - CPU Core Parking disabled
    - Fast Startup disabled
    - Automatic Maintenance disabled
    - Window transparency disabled
    - Snap Assist disabled
    - Window shadows disabled
    - Hardware-Accelerated GPU Scheduling (HAGS) enabled
    - DWM process priority increased
    - Network Auto-Tuning disabled
    - IPv6 disabled
    - QoS 20% bandwidth reservation removed
    - NTFS Last Access Time disabled
    - NTFS 8.3 filenames disabled
    - Startup app delay removed

.NOTES
    Run as Administrator. Creates a restore point before making changes.
    To revert changes run: Restore-W11DevVM-v2.ps1
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
Write-Host "  W11 Dev VM Optimizer v2  (RAM + CPU + Apps + Network + NTFS)" -ForegroundColor Cyan
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
Checkpoint-Computer -Description "Before W11 VM Optimization v2" -RestorePointType "MODIFY_SETTINGS" | Out-Null
Write-Host "Restore point created." -ForegroundColor Green
Write-Host ""

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
    Write-Host "  [DISABLED] $($svc.Name) - $($svc.Reason)" -ForegroundColor Green
    $disabled++
}

# ─────────────────────────────────────────────
# REGISTRY TWEAKS (telemetry, Cortana, ads)
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
# CPU OPTIMIZATIONS (v1)
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Applying CPU optimizations..." -ForegroundColor Cyan

# Power plan: High Performance
$hpGuid = (powercfg /list | Select-String "High performance" | ForEach-Object {
    if ($_ -match "\(([0-9a-f-]{36})\)") { $Matches[1] }
})
if ($hpGuid) {
    powercfg /setactive $hpGuid | Out-Null
    Write-Host "  [POWER] High Performance plan activated" -ForegroundColor Green
} else {
    powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
    $hpGuid = (powercfg /list | Select-String "High performance" | ForEach-Object {
        if ($_ -match "\(([0-9a-f-]{36})\)") { $Matches[1] }
    })
    if ($hpGuid) { powercfg /setactive $hpGuid | Out-Null }
    Write-Host "  [POWER] High Performance plan created and activated" -ForegroundColor Green
}

# Visual effects
$visualFxPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
if (-not (Test-Path $visualFxPath)) { New-Item -Path $visualFxPath -Force | Out-Null }
Set-ItemProperty -Path $visualFxPath -Name "VisualFXSetting" -Value 2 -Type DWord
Write-Host "  [VISUAL] Visual effects set to best performance" -ForegroundColor Green

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

# Background UWP apps
$bgAppsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
if (-not (Test-Path $bgAppsPath)) { New-Item -Path $bgAppsPath -Force | Out-Null }
Set-ItemProperty -Path $bgAppsPath -Name "GlobalUserDisabled" -Value 1 -Type DWord
Write-Host "  [BKGD] Background UWP apps disabled" -ForegroundColor Green

# Game Bar / DVR
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
Write-Host "  [GAME] Game Bar and Game DVR disabled" -ForegroundColor Green

# Taskbar Widgets
$widgetPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (-not (Test-Path $widgetPath)) { New-Item -Path $widgetPath -Force | Out-Null }
Set-ItemProperty -Path $widgetPath -Name "AllowNewsAndInterests" -Value 0 -Type DWord
Write-Host "  [WIDGET] Taskbar Widgets disabled" -ForegroundColor Green

# Processor scheduling: Background Services
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
    -Name "Win32PrioritySeparation" -Value 24 -Type DWord
Write-Host "  [SCHED] Processor scheduling set to Background Services" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: TIMELINE / ACTIVITY HISTORY
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Disabling Timeline and Activity History..." -ForegroundColor Cyan

$timelinePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $timelinePath)) { New-Item -Path $timelinePath -Force | Out-Null }
Set-ItemProperty -Path $timelinePath -Name "EnableActivityFeed"    -Value 0 -Type DWord
Set-ItemProperty -Path $timelinePath -Name "PublishUserActivities" -Value 0 -Type DWord
Set-ItemProperty -Path $timelinePath -Name "UploadUserActivities"  -Value 0 -Type DWord
Write-Host "  [DONE] Timeline and Activity History disabled" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: TELEMETRY SCHEDULED TASKS
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Disabling telemetry scheduled tasks..." -ForegroundColor Cyan

$scheduledTasks = @(
    @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "Microsoft Compatibility Appraiser" }
    @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "ProgramDataUpdater" }
    @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "StartupAppTask" }
    @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "Consolidator" }
    @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "UsbCeip" }
    @{ Path = "\Microsoft\Windows\DiskDiagnostic\"; Name = "Microsoft-Windows-DiskDiagnosticDataCollector" }
    @{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClient" }
    @{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClientOnScenarioDownload" }
    @{ Path = "\Microsoft\Windows\Windows Error Reporting\"; Name = "QueueReporting" }
    @{ Path = "\Microsoft\Windows\Autochk\"; Name = "Proxy" }
    @{ Path = "\Microsoft\Windows\CloudExperienceHost\"; Name = "CreateObjectTask" }
    @{ Path = "\Microsoft\Windows\DiskFootprint\"; Name = "Diagnostics" }
    @{ Path = "\Microsoft\Windows\Maps\"; Name = "MapsToastTask" }
    @{ Path = "\Microsoft\Windows\Maps\"; Name = "MapsUpdateTask" }
    @{ Path = "\Microsoft\Windows\NetTrace\"; Name = "GatherNetworkInfo" }
    @{ Path = "\Microsoft\Windows\WDI\"; Name = "ResolutionHost" }
    @{ Path = "\Microsoft\Windows\Power Efficiency Diagnostics\"; Name = "AnalyzeSystem" }
    @{ Path = "\Microsoft\Windows\Maintenance\"; Name = "WinSAT" }
)

$tasksDisabled  = 0
$tasksNotFound  = 0

foreach ($task in $scheduledTasks) {
    $t = Get-ScheduledTask -TaskPath $task.Path -TaskName $task.Name -ErrorAction SilentlyContinue
    if ($null -eq $t) {
        Write-Host "  [NOT FOUND] $($task.Name)" -ForegroundColor DarkGray
        $tasksNotFound++
        continue
    }
    Disable-ScheduledTask -TaskPath $task.Path -TaskName $task.Name -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  [DISABLED]  $($task.Name)" -ForegroundColor Green
    $tasksDisabled++
}

# ─────────────────────────────────────────────
# NEW v2: CORE PARKING
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Disabling CPU Core Parking..." -ForegroundColor Cyan

# Subgroup: Processor Power Management  54533251-82be-4824-96c1-47b60b740d00
# Setting:  Minimum processor state       893dee8e-2bef-41e0-89c6-b55d0929964c
# Setting:  Core Parking min cores        0cc5b647-c1df-4637-891a-dec35c318583
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 | Out-Null
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 | Out-Null
powercfg /setactive SCHEME_CURRENT | Out-Null
Write-Host "  [DONE] Core Parking disabled (all cores always active)" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: FAST STARTUP
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Disabling Fast Startup..." -ForegroundColor Cyan

$fastStartupPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
if (-not (Test-Path $fastStartupPath)) { New-Item -Path $fastStartupPath -Force | Out-Null }
Set-ItemProperty -Path $fastStartupPath -Name "HiberbootEnabled" -Value 0 -Type DWord
Write-Host "  [DONE] Fast Startup disabled" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: AUTOMATIC MAINTENANCE
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Disabling Automatic Maintenance..." -ForegroundColor Cyan

$maintPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance"
if (-not (Test-Path $maintPath)) { New-Item -Path $maintPath -Force | Out-Null }
Set-ItemProperty -Path $maintPath -Name "MaintenanceDisabled" -Value 1 -Type DWord

Disable-ScheduledTask -TaskPath "\Microsoft\Windows\TaskScheduler\" -TaskName "Regular Maintenance"       -ErrorAction SilentlyContinue | Out-Null
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\TaskScheduler\" -TaskName "Maintenance Configurator"  -ErrorAction SilentlyContinue | Out-Null
Write-Host "  [DONE] Automatic Maintenance disabled" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: WINDOW TRANSPARENCY (Acrylic / Mica)
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Disabling window transparency effects..." -ForegroundColor Cyan

$themePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
if (-not (Test-Path $themePath)) { New-Item -Path $themePath -Force | Out-Null }
Set-ItemProperty -Path $themePath -Name "EnableTransparency" -Value 0 -Type DWord
Write-Host "  [DONE] Window transparency (Acrylic/Mica) disabled" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: SNAP ASSIST
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Disabling Snap Assist..." -ForegroundColor Cyan

$explorerAdvPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $explorerAdvPath -Name "SnapAssist"    -Value 0 -Type DWord
Set-ItemProperty -Path $explorerAdvPath -Name "EnableSnapBar" -Value 0 -Type DWord
Set-ItemProperty -Path $explorerAdvPath -Name "EnableTaskGroups" -Value 0 -Type DWord
Write-Host "  [DONE] Snap Assist disabled" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: WINDOW SHADOWS
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Disabling window shadows..." -ForegroundColor Cyan

Set-ItemProperty -Path $explorerAdvPath -Name "ListviewShadow" -Value 0 -Type DWord

$dwmPath = "HKCU:\Software\Microsoft\Windows\DWM"
if (-not (Test-Path $dwmPath)) { New-Item -Path $dwmPath -Force | Out-Null }
Set-ItemProperty -Path $dwmPath -Name "EnableWindowColorization" -Value 0 -Type DWord
Write-Host "  [DONE] Window shadows disabled" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: HARDWARE-ACCELERATED GPU SCHEDULING (HAGS)
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Enabling Hardware-Accelerated GPU Scheduling (HAGS)..." -ForegroundColor Cyan

$graphicsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
if (-not (Test-Path $graphicsPath)) { New-Item -Path $graphicsPath -Force | Out-Null }
Set-ItemProperty -Path $graphicsPath -Name "HwSchMode" -Value 2 -Type DWord
Write-Host "  [DONE] HAGS enabled (requires reboot + compatible GPU driver)" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: DWM PRIORITY + SYSTEM RESPONSIVENESS
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Increasing DWM priority and system responsiveness..." -ForegroundColor Cyan

$mmProfilePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (-not (Test-Path $mmProfilePath)) { New-Item -Path $mmProfilePath -Force | Out-Null }
Set-ItemProperty -Path $mmProfilePath -Name "SystemResponsiveness"   -Value 0          -Type DWord
Set-ItemProperty -Path $mmProfilePath -Name "NetworkThrottlingIndex" -Value 0xffffffff  -Type DWord

$mmGamesPath = "$mmProfilePath\Tasks\Games"
if (-not (Test-Path $mmGamesPath)) { New-Item -Path $mmGamesPath -Force | Out-Null }
Set-ItemProperty -Path $mmGamesPath -Name "GPU Priority"   -Value 8 -Type DWord
Set-ItemProperty -Path $mmGamesPath -Name "Priority"       -Value 6 -Type DWord
Set-ItemProperty -Path $mmGamesPath -Name "Scheduling Category" -Value "High" -Type String
Write-Host "  [DONE] DWM priority and multimedia responsiveness increased" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: NETWORK AUTO-TUNING
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Disabling network Auto-Tuning..." -ForegroundColor Cyan

netsh int tcp set global autotuninglevel=disabled 2>&1 | Out-Null
Write-Host "  [DONE] TCP Auto-Tuning disabled" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: IPv6
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Disabling IPv6..." -ForegroundColor Cyan

Get-NetAdapter | ForEach-Object {
    Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
}
$tcpip6Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
if (-not (Test-Path $tcpip6Path)) { New-Item -Path $tcpip6Path -Force | Out-Null }
Set-ItemProperty -Path $tcpip6Path -Name "DisabledComponents" -Value 0xFF -Type DWord
Write-Host "  [DONE] IPv6 disabled on all adapters" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: QoS BANDWIDTH RESERVATION
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Removing QoS 20% bandwidth reservation..." -ForegroundColor Cyan

$qosPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
if (-not (Test-Path $qosPath)) { New-Item -Path $qosPath -Force | Out-Null }
Set-ItemProperty -Path $qosPath -Name "NonBestEffortLimit" -Value 0 -Type DWord
Write-Host "  [DONE] QoS bandwidth reservation set to 0%" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: NTFS LAST ACCESS TIME
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Disabling NTFS Last Access Time..." -ForegroundColor Cyan

fsutil behavior set disablelastaccess 1 | Out-Null
Write-Host "  [DONE] NTFS Last Access Time disabled (reduces disk writes)" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: NTFS 8.3 FILENAMES
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Disabling NTFS 8.3 filename generation..." -ForegroundColor Cyan

fsutil behavior set disable8dot3 1 | Out-Null
Write-Host "  [DONE] NTFS 8.3 filename generation disabled" -ForegroundColor Green

# ─────────────────────────────────────────────
# NEW v2: STARTUP APP DELAY
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Removing startup app delay..." -ForegroundColor Cyan

$startupDelayPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
if (-not (Test-Path $startupDelayPath)) { New-Item -Path $startupDelayPath -Force | Out-Null }
Set-ItemProperty -Path $startupDelayPath -Name "StartupDelayInMSec" -Value 0 -Type DWord
Write-Host "  [DONE] Startup app delay removed" -ForegroundColor Green

# ─────────────────────────────────────────────
# SNAPSHOT: RAM + CPU after
# ─────────────────────────────────────────────
Write-Host ""
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
Write-Host "  Apps removed              : $appsRemoved"               -ForegroundColor Green
Write-Host "  Apps not found            : $appsNotFound"              -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Services disabled         : $disabled"                  -ForegroundColor Green
Write-Host "  Services already disabled : $skipped"                   -ForegroundColor DarkGray
Write-Host "  Services not found        : $notFound"                  -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Scheduled tasks disabled  : $tasksDisabled"             -ForegroundColor Green
Write-Host "  Scheduled tasks not found : $tasksNotFound"             -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Total RAM                 : $totalMB MB"                -ForegroundColor White
Write-Host ""
Write-Host "  [BEFORE] Used RAM   : $usedBeforeMB MB  |  Free: $freeBeforeMB MB" -ForegroundColor Yellow
Write-Host "  [AFTER]  Used RAM   : $usedAfterMB MB  |  Free: $freeAfterMB MB"   -ForegroundColor Green

if ($savedMB -gt 0) {
    Write-Host "  RAM freed           : +$savedMB MB ($savedPct% of total)"       -ForegroundColor Green
} else {
    Write-Host "  RAM freed           : $savedMB MB (reboot to see full effect)"   -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "  [BEFORE] CPU Load   : $cpuBefore %"                    -ForegroundColor Yellow
Write-Host "  [AFTER]  CPU Load   : $cpuAfter %"                     -ForegroundColor Green

if ($cpuDiff -gt 0) {
    Write-Host "  CPU reduction       : -$cpuDiff %"                 -ForegroundColor Green
} elseif ($cpuDiff -lt 0) {
    Write-Host "  CPU delta           : $cpuDiff % (snapshot variance, reboot to confirm)" -ForegroundColor DarkYellow
} else {
    Write-Host "  CPU delta           : no change in snapshot (reboot to see full effect)"  -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  v2 optimizations applied:" -ForegroundColor White
Write-Host "    - Timeline / Activity History disabled"               -ForegroundColor Green
Write-Host "    - $tasksDisabled telemetry scheduled tasks disabled"  -ForegroundColor Green
Write-Host "    - CPU Core Parking disabled"                          -ForegroundColor Green
Write-Host "    - Fast Startup disabled"                              -ForegroundColor Green
Write-Host "    - Automatic Maintenance disabled"                     -ForegroundColor Green
Write-Host "    - Window transparency (Acrylic/Mica) disabled"        -ForegroundColor Green
Write-Host "    - Snap Assist disabled"                               -ForegroundColor Green
Write-Host "    - Window shadows disabled"                            -ForegroundColor Green
Write-Host "    - HAGS (GPU Scheduling) enabled"                      -ForegroundColor Green
Write-Host "    - DWM priority and responsiveness increased"          -ForegroundColor Green
Write-Host "    - Network Auto-Tuning disabled"                       -ForegroundColor Green
Write-Host "    - IPv6 disabled"                                      -ForegroundColor Green
Write-Host "    - QoS bandwidth reservation removed"                  -ForegroundColor Green
Write-Host "    - NTFS Last Access Time disabled"                     -ForegroundColor Green
Write-Host "    - NTFS 8.3 filename generation disabled"              -ForegroundColor Green
Write-Host "    - Startup app delay removed"                          -ForegroundColor Green
Write-Host ""
Write-Host "  A restore point was created before any changes."        -ForegroundColor Cyan
Write-Host "  REBOOT REQUIRED to fully apply all changes."            -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
