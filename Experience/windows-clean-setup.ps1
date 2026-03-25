#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 Clean & Private Environment Setup
    Inspired by the minimalist GNOME experience

.DESCRIPTION
    - Removes recent files and activity traces
    - Disables personal information leaks
    - Cleans and simplifies the Windows 11 UI
    - Configures maximum privacy without breaking the system

.NOTES
    Run as Administrator:
    Right-click PowerShell > "Run as Administrator"
    or from terminal: Start-Process powershell -Verb runAs
#>

# ============================================================
# HELPERS
# ============================================================

function Write-Section($title) {
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor DarkGray
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor DarkGray
}

function Write-OK($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-INFO($msg) { Write-Host "  [--] $msg" -ForegroundColor DarkGray }

function Set-RegistryValue($path, $name, $value, $type = "DWord") {
    try {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force -ErrorAction Stop
        return $true
    } catch {
        Write-Host "  [WARN] Could not set $name : $_" -ForegroundColor Yellow
        return $false
    }
}

Write-Host ""
Write-Host "  ============================================" -ForegroundColor Magenta
Write-Host "  Windows 11 - Clean & Private Environment" -ForegroundColor Magenta
Write-Host "  ============================================" -ForegroundColor Magenta
Write-Host ""


# ============================================================
# 1. RECENT FILES & QUICK ACCESS
# ============================================================
Write-Section "1. Recent Files & Quick Access"

# Disable recent and frequent files in Explorer Quick Access
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 0
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowFrequent" 0
Write-OK "Quick Access: recent and frequent files disabled"

# Clear recent files history
$recentPaths = @(
    "$env:APPDATA\Microsoft\Windows\Recent\*",
    "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*",
    "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations\*"
)
foreach ($path in $recentPaths) {
    Remove-Item -Path $path -Force -Recurse -ErrorAction SilentlyContinue
}
Write-OK "Recent files history cleared"

# Disable document tracking in Start Menu Jump Lists
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackDocs" 0
Write-OK "Document tracking in Start Menu disabled"

# Disable Jump Lists (recent files list in taskbar)
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0
Write-OK "Jump Lists disabled"


# ============================================================
# 2. ACTIVITY HISTORY (TIMELINE)
# ============================================================
Write-Section "2. Activity History"

$null = Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
$null = Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
$null = Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" 0
Write-OK "Activity Feed (Timeline) disabled"

# Clear accumulated activity history by removing the registry key
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ActivityDataModel" -Recurse -Force -ErrorAction SilentlyContinue
Write-OK "Activity history cleared"


# ============================================================
# 3. SEARCH & CORTANA
# ============================================================
Write-Section "3. Search & Cortana"

# Disable search history
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled" 0
Write-OK "Search history disabled"

# Disable Bing suggestions in local search
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0
Write-OK "Bing in local search disabled"

# Disable location-based search
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "AllowSearchToUseLocation" 0
Write-OK "Location-based search disabled"

# Clear Explorer search history (WordWheel) - remove all values under the key
$wordWheelPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"
if (Test-Path $wordWheelPath) {
    Remove-Item -Path $wordWheelPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-OK "Explorer search history (WordWheel) cleared"
}


# ============================================================
# 4. CLIPBOARD
# ============================================================
Write-Section "4. Clipboard"

# Disable clipboard history (Win+V)
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Clipboard" "EnableClipboardHistory" 0
Write-OK "Clipboard history disabled"

# Disable cross-device clipboard sync
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Clipboard" "CloudClipboardAutomaticUpload" 0
Write-OK "Cloud clipboard sync disabled"

# Clear current clipboard contents
Start-Process "cmd.exe" -ArgumentList "/c", "echo.|clip" -WindowStyle Hidden -Wait
Write-OK "Clipboard cleared"


# ============================================================
# 5. TELEMETRY & DIAGNOSTICS
# ============================================================
Write-Section "5. Telemetry & Diagnostics"

$null = Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
$null = Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
Write-OK "Telemetry reduced to minimum"

# Disable Customer Experience Improvement Program
$null = Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" "CEIPEnable" 0
Write-OK "CEIP disabled"

# Disable error reporting to Microsoft
$null = Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
Write-OK "Windows Error Reporting disabled"

# Disable inking and typing diagnostics
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Input\TIPC" "Enabled" 0
Write-OK "Inking and typing diagnostics disabled"


# ============================================================
# 6. APP PRIVACY
# ============================================================
Write-Section "6. App Privacy"

# Disable advertising ID
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
Write-OK "Advertising ID disabled"

# Disable app launch tracking
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0
Write-OK "App launch tracking in Start disabled"

# Disable personalized suggestions
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" 0
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled" 0
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353696Enabled" 0
Write-OK "Personalized suggestions disabled"

# Disable silent app installs (bloatware)
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SilentInstalledAppsEnabled" 0
Write-OK "Silent app installs disabled"


# ============================================================
# 7. TASKBAR -- CLEAN MODE (GNOME-style)
# ============================================================
Write-Section "7. Taskbar -- Clean Mode"

# Move taskbar icons to the left
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 0
Write-OK "Taskbar aligned to the left"

# Hide search button from taskbar
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 0
Write-OK "Search button hidden from taskbar"

# Hide Task View button
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" 0
Write-OK "Task View button hidden"

# Hide Widgets button
$null = Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
Write-OK "Widgets hidden from taskbar"

# Hide Chat (Teams) button
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" 0
Write-OK "Chat/Teams button hidden"

# Hide News and Interests
$null = Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" 0
Write-OK "News and Interests hidden"


# ============================================================
# 8. EXPLORER -- CLEAN VIEW
# ============================================================
Write-Section "8. Explorer -- Clean View"

$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0
Write-OK "File extensions visible"

# Open Explorer to "This PC" instead of Quick Access
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1
Write-OK "Explorer opens to 'This PC'"

# Disable OneDrive sync ads in Explorer
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSyncProviderNotifications" 0
Write-OK "OneDrive notifications in Explorer disabled"


# ============================================================
# 9. START MENU -- CLEAN
# ============================================================
Write-Section "9. Start Menu -- Clean"

# Disable recommended apps in Start
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" 0
Write-OK "Recommendations in Start Menu disabled"

# Disable cloud content in Start
$null = Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
$null = Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableCloudOptimizedContent" 1
Write-OK "Cloud content in Start Menu disabled"


# ============================================================
# 10. LOCK SCREEN -- PRIVACY
# ============================================================
Write-Section "10. Lock Screen"

# Disable notifications on lock screen
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" 0
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" 0
Write-OK "Notifications on lock screen disabled"

# Disable Bing/Spotlight images on lock screen
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" 0
$null = Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenOverlayEnabled" 0
Write-OK "Bing/Spotlight images on lock screen disabled"


# ============================================================
# 11. SUPERFETCH / SYSMAIN (SSD optimization)
# ============================================================
Write-Section "11. SuperFetch / SysMain"

$superfetch = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
if ($superfetch) {
    Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "SysMain" -StartupType Disabled
    Write-OK "SysMain (SuperFetch) disabled"
} else {
    Write-INFO "SysMain not found"
}


# ============================================================
# 12. CLEAN TEMPORARY FILES
# ============================================================
Write-Section "12. Temporary Files Cleanup"

$tempPaths = @(
    $env:TEMP,
    $env:TMP,
    "C:\Windows\Temp",
    "$env:LOCALAPPDATA\Temp",
    "$env:APPDATA\Microsoft\Windows\Recent",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
)

$totalCleaned = 0
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        $sizeResult = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
                      Measure-Object -Property Length -Sum
        $before = if ($sizeResult.Sum) { $sizeResult.Sum } else { 0 }
        Remove-Item -Path "$path\*" -Force -Recurse -ErrorAction SilentlyContinue
        $totalCleaned += $before
        Write-OK "Cleaned: $path"
    }
}

$cleanedMB = [math]::Round($totalCleaned / 1MB, 2)
Write-Host ""
Write-Host "  Total freed: $cleanedMB MB" -ForegroundColor Yellow


# ============================================================
# 13. RESTART EXPLORER
# ============================================================
Write-Section "13. Applying Changes"

Write-INFO "Restarting Explorer to apply visual changes..."
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process "explorer.exe"
Write-OK "Explorer restarted"


# ============================================================
# SUMMARY
# ============================================================
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Green
Write-Host "  DONE" -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Your Windows 11 now has:" -ForegroundColor White
Write-Host ""
Write-Host "  Privacy" -ForegroundColor Cyan
Write-Host "  - No recent files or Jump Lists"
Write-Host "  - No search or activity history"
Write-Host "  - No telemetry or advertising ID"
Write-Host "  - No clipboard sync"
Write-Host "  - No notifications on lock screen"
Write-Host ""
Write-Host "  Clean UI (GNOME-style)" -ForegroundColor Cyan
Write-Host "  - Taskbar aligned to the left"
Write-Host "  - No Widgets, Chat, or Task View on taskbar"
Write-Host "  - No Bing in local search"
Write-Host "  - Explorer opens to 'This PC'"
Write-Host "  - No recommendations in Start Menu"
Write-Host ""
Write-Host ""
