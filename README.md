# win-optimization

PowerShell scripts to optimize and configure Windows 11 for performance, privacy, and a clean environment.

---

## Structure

```
win-optimization/
├── Optimization/
│   ├── Optimize-W11DevVM-v2.ps1   # Full VM optimization (performance, privacy, services)
│   └── INSTRUCTIONS.md            # Step-by-step execution guide
└── Experience/
    ├── windows-clean-setup.ps1    # Clean & private environment (GNOME-style UI)
    └── Set-RoyalTheme.ps1         # Royal XP Blue theme with rollback support
```

---

## Optimization

Full optimization for Windows 11 virtual machines used in corporate development environments targeting **Office 365** and **Microsoft Teams**.

### Usage

Run **as Administrator** in PowerShell:

```powershell
# Allow execution for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Run the optimization
.\Optimization\Optimize-W11DevVM-v2.ps1
```

> A System Restore point named **"Before W11 VM Optimization v2"** is created automatically before any changes are applied.
>
> See `Optimization\INSTRUCTIONS.md` for the full step-by-step guide.

### What it does

**Apps removed**

| App | Package Name |
|---|---|
| Xbox App | `Microsoft.XboxApp` |
| Xbox Game Overlay | `Microsoft.XboxGameOverlay` |
| Xbox Gaming Overlay | `Microsoft.XboxGamingOverlay` |
| Xbox Identity Provider | `Microsoft.XboxIdentityProvider` |
| Xbox Speech To Text Overlay | `Microsoft.XboxSpeechToTextOverlay` |
| Xbox TCUI | `Microsoft.Xbox.TCUI` |
| Gaming App | `Microsoft.GamingApp` |
| Groove Music | `Microsoft.ZuneMusic` |
| Movies & TV | `Microsoft.ZuneVideo` |
| Sound Recorder | `Microsoft.WindowsSoundRecorder` |
| Mixed Reality Portal | `Microsoft.MixedReality.Portal` |
| 3D Viewer | `Microsoft.Microsoft3DViewer` |
| Print 3D | `Microsoft.Print3D` |
| 3D Builder | `Microsoft.3DBuilder` |
| Skype | `Microsoft.SkypeApp` |
| People | `Microsoft.People` |
| Microsoft Solitaire Collection | `Microsoft.MicrosoftSolitaireCollection` |
| Microsoft News (Bing News) | `Microsoft.BingNews` |
| Weather | `Microsoft.BingWeather` |
| Bing Finance | `Microsoft.BingFinance` |
| Bing Sports | `Microsoft.BingSports` |
| Bing Translator | `Microsoft.BingTranslator` |
| Candy Crush Saga | `king.com.CandyCrushSaga` |
| Candy Crush Friends | `king.com.CandyCrushFriends` |
| Bubble Witch 3 Saga | `king.com.BubbleWitch3Saga` |
| Farm Heroes Saga | `king.com.FarmHeroesSaga` |
| Spotify | `SpotifyAB.SpotifyMusic` |
| TikTok | `BytedancePte.Ltd.TikTok` |
| Netflix | `Netflix.Netflix` |
| Prime Video | `AmazonVideo.PrimeVideo` |
| Disney+ | `Disney.37853D22215E2` |
| Facebook | `Facebook.Facebook` |
| Instagram | `Instagram.Instagram` |
| Twitter / X | `Twitter.Twitter` |
| Hulu | `Hulu.HuluApp` |
| Flipboard | `Flipboard.Flipboard` |
| Pandora | `PandoraMediaInc.29680B314EFC2` |
| Adobe Photoshop Express | `AdobeSystemsIncorporated.AdobePhotoshopExpress` |
| Microsoft To Do | `Microsoft.Todos` |
| Get Office (promo app) | `Microsoft.MicrosoftOfficeHub` |
| Feedback Hub | `Microsoft.WindowsFeedbackHub` |
| Get Help | `Microsoft.GetHelp` |
| Tips | `Microsoft.Getstarted` |
| Windows Maps | `Microsoft.WindowsMaps` |
| Sticky Notes | `Microsoft.MicrosoftStickyNotes` |
| Power Automate Desktop | `Microsoft.PowerAutomateDesktop` |
| Wallet | `Microsoft.Wallet` |
| Cortana App | `Microsoft.549981C3F5F10` |
| Whiteboard | `Microsoft.Whiteboard` |

> **Preserved:** Office 365, Teams, OneDrive, Notepad, Calculator, Paint, Snipping Tool, Windows Terminal, Microsoft Store.

**Services disabled**

| Category | Services |
|---|---|
| Telemetry & Diagnostics | `DiagTrack`, `dmwappushservice`, `PcaSvc`, `DPS`, `WdiServiceHost`, `WdiSystemHost` |
| Search & Prefetch | `WSearch`, `SysMain` |
| Gaming & Xbox | `XblAuthManager`, `XblGameSave`, `XboxNetApiSvc`, `XboxGipSvc`, `GamingServices`, `spectrum`, `perceptionsimulation`, `WMPNetworkSvc`, `RetailDemo`, `MapsBroker` |
| Remote Access | `RemoteRegistry`, `RemoteAccess`, `SessionEnv`, `TermService`, `UmRdpService`, `RasMan`, `RasAuto`, `SstpSvc` |
| Printing & Scanning | `Spooler`, `PrintNotify`, `stisvc` |
| Fax & Telephony | `Fax`, `TapiSrv` |
| Biometrics & Sensors | `WbioSrvc`, `SensrSvc`, `SensorDataService`, `SensorService` |
| Smart Card | `SCardSvr`, `ScDeviceEnum`, `SCPolicySvc` |
| Bluetooth | `bthserv`, `BTAGService`, `BthAvctpSvc` |
| Tablet & Camera | `TabletInputService`, `FrameServer` |
| Error Reporting | `wercplsupport`, `WerSvc` |
| Miscellaneous | `seclogon`, `CscService`, `HomeGroupListener`, `HomeGroupProvider` |

**CPU & Performance**

| Optimization | Detail |
|---|---|
| Power plan | Set to **High Performance** |
| Visual effects | Disabled (best performance mode) |
| Animations | Taskbar, window, and menu animations disabled |
| Background UWP apps | Global disable via registry |
| Game Bar / Game DVR | Disabled via registry + policy |
| Processor scheduling | Set to **Background Services** (benefits compilers and dev servers) |
| Core Parking | Disabled — all CPU cores stay active, eliminates micro-stutters in VMs |
| Fast Startup | Disabled — prevents hybrid boot state that causes I/O and CPU overhead |
| Automatic Maintenance | Disabled — stops background defrag, indexing, and diagnostics |
| Telemetry scheduled tasks | 18 background tasks disabled |

**Window Fluidity**

| Optimization | Detail |
|---|---|
| Transparency (Acrylic/Mica) | Disabled — removes constant GPU/CPU blur rendering |
| Snap Assist | Disabled — removes overlay animations when moving windows |
| Window shadows | Disabled — reduces DWM rendering overhead |
| HAGS | Enabled — Hardware-Accelerated GPU Scheduling reduces frame latency |
| DWM priority | Increased — Desktop Window Manager gets higher scheduling priority |

**Network**

| Optimization | Detail |
|---|---|
| TCP Auto-Tuning | Disabled — reduces overhead on VM virtual adapters |
| IPv6 | Disabled on all adapters — removes unused network stack overhead |
| QoS bandwidth reservation | Set to 0% — removes the default 20% bandwidth reservation |

**NTFS / Disk**

| Optimization | Detail |
|---|---|
| Last Access Time | Disabled — eliminates write on every file read |
| 8.3 filename generation | Disabled — removes legacy short filename creation overhead |
| Startup app delay | Removed — eliminates the 10-second artificial delay Windows adds at boot |

### HTML log

When the script finishes it automatically generates `optimize-v2-log.html` in the same folder.
Open it in any browser to see the full execution log with colors.

### Restoring changes

> There is no restore script. Use the **System Restore point** created automatically at optimization time.
>
> Press `Win + R` → type `rstrui` → select **"Before W11 VM Optimization v2"**.
>
> **Note:** Removed apps cannot be restored via System Restore. Use the Microsoft Store to reinstall them individually.

---

## Experience

Scripts that improve the daily Windows 11 experience: a clean private environment and a custom visual theme.

---

### windows-clean-setup.ps1

Configures a clean, private Windows 11 environment inspired by the minimalist GNOME experience.

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\Experience\windows-clean-setup.ps1
```

**Privacy**
- Disables recent files and Jump Lists
- Clears and disables activity history (Timeline)
- Disables search history and Bing in local search
- Disables clipboard history and cloud sync
- Disables telemetry, advertising ID, and error reporting
- Disables personalized suggestions and silent app installs
- Disables notifications and Bing/Spotlight on lock screen

**Clean UI (GNOME-style)**
- Taskbar aligned to the left
- Removes Widgets, Chat (Teams), and Task View buttons from taskbar
- Hides search button from taskbar
- Explorer opens to "This PC" instead of Quick Access
- Removes recommendations from Start Menu
- Disables cloud content in Start Menu

**Performance**
- Disables SysMain (SuperFetch) — recommended for SSDs
- Cleans temporary files and caches

---

### Set-RoyalTheme.ps1

Applies a Royal Blue (Windows XP-inspired) visual theme via registry, with full rollback support.

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Apply Royal theme
.\Experience\Set-RoyalTheme.ps1

# Undo and restore previous theme
.\Experience\Set-RoyalTheme.ps1 -Rollback
```

**What it applies**

| Setting | Value | Effect |
|---|---|---|
| `AppsUseLightTheme` | `1` | Apps in light mode |
| `SystemUsesLightTheme` | `1` | Shell and taskbar in light mode |
| `ColorPrevalence` | `1` | Accent color shown on taskbar and title bars |
| `AccentColor` | `#003399` | Royal Blue on taskbar and Start button |
| `AccentColorInactive` | `#1A4DB5` | Muted Royal Blue on inactive title bars |
| `ColorizationColor` | `#003399` (80% opacity) | Royal Blue window borders |
| `ColorizationColorBalance` | `78` | Rich saturated color (classic XP feel) |

**Rollback**

Before applying any change, the script saves a backup of the current registry values to `Experience\royal-theme-backup.json`.

Running with `-Rollback`:
- Restores values that existed before to their original state
- Removes values that were not present before (no residue)
- Leaves the registry exactly as it was
