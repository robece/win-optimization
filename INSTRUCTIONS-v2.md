# Execution Instructions — v2

## Requirements

- Windows 11
- PowerShell 5.1 or later
- Administrator account

> Run `Optimize-W11DevVM-v2.ps1` as a **standalone** script.
> It includes all v1 optimizations plus the new v2 ones.
> You do not need to run v1 first.

---

## How to run

### 1. Download the scripts

Download the repository as a ZIP from GitHub and extract it, or clone it:

```powershell
git clone https://github.com/robece/win-optimization.git
cd win-optimization
```

### 2. Open PowerShell as Administrator

- Press `Win + X` and select **Terminal (Admin)** or **Windows PowerShell (Admin)**
- Or search for "PowerShell" in the Start menu → right-click → **Run as administrator**

### 3. Navigate to the folder

```powershell
cd "C:\path\to\win-optimization"
```

### 4. Allow script execution for this session

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

> This only applies to the current PowerShell session. Nothing is changed permanently.

### 5. Run the v2 optimization script

```powershell
.\Optimize-W11DevVM-v2.ps1
```

### 5a. Run and save output to a log file (optional)

```powershell
.\Optimize-W11DevVM-v2.ps1 | Tee-Object -FilePath "C:\optimize-v2-log.txt"
```

The log file will be saved at `C:\optimize-v2-log.txt`.

### 6. Reboot

A reboot is **required** after the script finishes. Some optimizations
(HAGS, NTFS, IPv6, Core Parking) only take effect after a full restart.

---

## What this script does (v2 additions)

| Area | Optimization |
|---|---|
| RAM | Timeline and Activity History disabled |
| CPU | 18 telemetry scheduled tasks disabled |
| CPU | Core Parking disabled (all cores always active) |
| CPU | Fast Startup disabled |
| CPU | Automatic Maintenance disabled |
| Fluidity | Window transparency (Acrylic/Mica) disabled |
| Fluidity | Snap Assist disabled |
| Fluidity | Window shadows disabled |
| Fluidity | Hardware-Accelerated GPU Scheduling (HAGS) enabled |
| Fluidity | DWM priority and system responsiveness increased |
| Network | TCP Auto-Tuning disabled |
| Network | IPv6 disabled on all adapters |
| Network | QoS 20% bandwidth reservation removed |
| Disk | NTFS Last Access Time disabled |
| Disk | NTFS 8.3 filename generation disabled |
| Startup | Startup app delay removed |

> All v1 optimizations (services, apps, power plan, visual effects,
> Game Bar, Widgets, background apps) are also included in v2.

---

## How to revert

To re-enable services and restore registry/CPU settings to Windows defaults:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\Restore-W11DevVM.ps1
```

> **Note:** Apps removed by the optimization scripts cannot be restored via script.
> Use the Microsoft Store to reinstall them, or use the System Restore point
> that was created automatically before the optimization ran.

---

## Restore point

A System Restore point named **"Before W11 VM Optimization v2"** is created
automatically at the start of `Optimize-W11DevVM-v2.ps1`.

To access it:

1. Press `Win + R` → type `rstrui` → press Enter
2. Select **"Before W11 VM Optimization v2"**
3. Follow the wizard
