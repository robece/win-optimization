# win-optimization

PowerShell scripts to optimize a Windows 11 virtual machine for corporate development.
Targets environments using **Office 365** and **Microsoft Teams**.

---

## Scripts

| Script | Description |
|---|---|
| `Optimize-W11DevVM.ps1` | v1 — Removes bloatware, disables services, applies CPU/RAM tweaks |
| `Optimize-W11DevVM-v2.ps1` | v2 — All v1 optimizations + network, NTFS, fluidity, scheduled tasks |
| `Restore-W11DevVM.ps1` | Re-enables services and reverts registry/CPU changes |
| `INSTRUCTIONS.md` | Step-by-step guide for running v1 |
| `INSTRUCTIONS-v2.md` | Step-by-step guide for running v2 |

> **Recommendation:** Run `Optimize-W11DevVM-v2.ps1` — it is a standalone script
> that includes everything from v1 plus all v2 optimizations. You do not need to run v1 first.

## Usage

Run **as Administrator** in PowerShell:

```powershell
# Allow execution for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Run v2 (recommended — includes everything)
.\Optimize-W11DevVM-v2.ps1

# Run v1 only
.\Optimize-W11DevVM.ps1

# Revert (services + registry only — apps must be reinstalled manually)
.\Restore-W11DevVM.ps1
```

> A System Restore point is created automatically before any changes are applied.

---

## What gets removed (Apps)

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

> **Preserved:** Office 365, Teams, OneDrive, Notepad, Calculator, Paint, Snipping Tool, Windows Terminal.

---

## What gets disabled (Services)

### Telemetry & Diagnostics
| Service Name | Display Name |
|---|---|
| `DiagTrack` | Connected User Experiences and Telemetry |
| `dmwappushservice` | WAP Push Message Routing Service |
| `PcaSvc` | Program Compatibility Assistant Service |
| `DPS` | Diagnostic Policy Service |
| `WdiServiceHost` | Diagnostic Service Host |
| `WdiSystemHost` | Diagnostic System Host |

### Search & Prefetch (CPU/IO)
| Service Name | Display Name |
|---|---|
| `WSearch` | Windows Search (indexing) |
| `SysMain` | Superfetch / SysMain |

### Gaming & Xbox
| Service Name | Display Name |
|---|---|
| `XblAuthManager` | Xbox Live Auth Manager |
| `XblGameSave` | Xbox Live Game Save |
| `XboxNetApiSvc` | Xbox Live Networking Service |
| `XboxGipSvc` | Xbox Accessory Management Service |
| `GamingServices` | Gaming Services |
| `spectrum` | Windows Perception Service |
| `perceptionsimulation` | Windows Perception Simulation Service |
| `WMPNetworkSvc` | Windows Media Player Network Sharing |
| `RetailDemo` | Device Management Retail Demo Service |
| `MapsBroker` | Downloaded Maps Manager |
| `InstallService` | Microsoft Store Install Service |

### Remote Access
| Service Name | Display Name |
|---|---|
| `RemoteRegistry` | Remote Registry |
| `RemoteAccess` | Routing and Remote Access |
| `SessionEnv` | Remote Desktop Configuration |
| `TermService` | Remote Desktop Services |
| `UmRdpService` | Remote Desktop Device Redirector Driver |
| `RasMan` | Remote Access Connection Manager |
| `RasAuto` | Remote Access Auto Connection Manager |
| `SstpSvc` | Secure Socket Tunneling Protocol Service |

### Printing & Scanning
| Service Name | Display Name |
|---|---|
| `Spooler` | Print Spooler |
| `PrintNotify` | Printer Extensions and Notifications |
| `stisvc` | Windows Image Acquisition (WIA) |

### Fax & Telephony
| Service Name | Display Name |
|---|---|
| `Fax` | Fax |
| `TapiSrv` | Telephony |

### Biometrics & Sensors
| Service Name | Display Name |
|---|---|
| `WbioSrvc` | Windows Biometric Service |
| `SensrSvc` | Sensor Monitoring Service |
| `SensorDataService` | Sensor Data Service |
| `SensorService` | Sensor Service |

### Smart Card
| Service Name | Display Name |
|---|---|
| `SCardSvr` | Smart Card |
| `ScDeviceEnum` | Smart Card Device Enumeration Service |
| `SCPolicySvc` | Smart Card Removal Policy |

### Parental Controls
| Service Name | Display Name |
|---|---|
| `WpcMonSvc` | Parental Controls |

### Bluetooth
| Service Name | Display Name |
|---|---|
| `bthserv` | Bluetooth Support Service |
| `BTAGService` | Bluetooth Audio Gateway Service |
| `BthAvctpSvc` | AVCTP Service |

### Tablet & Camera
| Service Name | Display Name |
|---|---|
| `TabletInputService` | Touch Keyboard and Handwriting Panel Service |
| `FrameServer` | Windows Camera Frame Server |

### Error Reporting
| Service Name | Display Name |
|---|---|
| `wercplsupport` | Problem Reports Control Panel Support |
| `WerSvc` | Windows Error Reporting Service |

### Miscellaneous
| Service Name | Display Name |
|---|---|
| `seclogon` | Secondary Logon |
| `CscService` | Offline Files |
| `HomeGroupListener` | HomeGroup Listener |
| `HomeGroupProvider` | HomeGroup Provider |

---

## CPU optimizations applied

| Optimization | Detail |
|---|---|
| Power plan | Set to **High Performance** |
| Visual effects | Disabled (best performance mode) |
| Animations | Taskbar, window, menu animations disabled |
| Background UWP apps | Global disable via registry |
| Game Bar / Game DVR | Disabled via registry + policy |
| Taskbar Widgets | Disabled via policy |
| Processor scheduling | Set to **Background Services** (benefits compilers, dev servers) |

---

## Registry tweaks applied

| Key | Value | Effect |
|---|---|---|
| `HKLM:\..\Windows Search\AllowCortana` | `0` | Disables Cortana |
| `HKLM:\..\DataCollection\AllowTelemetry` | `0` | Disables telemetry |
| `HKCU:\..\AdvertisingInfo\Enabled` | `0` | Disables advertising ID |

---

## v2 — Additional optimizations

### RAM
| Optimization | Detail |
|---|---|
| Timeline / Activity History | Disabled via policy registry keys |

### CPU
| Optimization | Detail |
|---|---|
| Telemetry scheduled tasks | 18 background tasks disabled (diagnostics, CEIP, error reporting, maps, etc.) |
| Core Parking | Disabled — all CPU cores stay active, eliminates micro-stutters in VMs |
| Fast Startup | Disabled — prevents hybrid boot state that causes I/O and CPU overhead |
| Automatic Maintenance | Disabled — stops background defrag, indexing, and diagnostics |

### Window Fluidity
| Optimization | Detail |
|---|---|
| Transparency (Acrylic/Mica) | Disabled — removes constant GPU/CPU blur rendering |
| Snap Assist | Disabled — removes overlay animations when moving windows |
| Window shadows | Disabled — reduces DWM rendering overhead |
| HAGS | Enabled — Hardware-Accelerated GPU Scheduling reduces frame latency |
| DWM priority | Increased — Desktop Window Manager gets higher scheduling priority |

### Network
| Optimization | Detail |
|---|---|
| TCP Auto-Tuning | Disabled — reduces overhead on VM virtual adapters |
| IPv6 | Disabled on all adapters — removes unused network stack overhead |
| QoS bandwidth reservation | Set to 0% — removes the default 20% bandwidth reservation |

### NTFS / Disk
| Optimization | Detail |
|---|---|
| Last Access Time | Disabled — eliminates write on every file read |
| 8.3 filename generation | Disabled — removes legacy short filename creation overhead |

### Startup
| Optimization | Detail |
|---|---|
| Startup app delay | Removed — eliminates the 10-second artificial delay Windows adds at boot |

---

## Restoring changes

Run `Restore-W11DevVM.ps1` as Administrator to re-enable services, revert registry keys,
restore the Balanced power plan, and re-enable visual effects.

> **Note:** Removed apps cannot be restored via `Restore-W11DevVM.ps1`.
> Use the Microsoft Store to reinstall them individually, or use the
> System Restore point created at optimization time.
