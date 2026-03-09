# Execution Instructions

## Requirements

- Windows 11
- PowerShell 5.1 or later
- Administrator account

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

### 5. Run the optimization script

```powershell
.\Optimize-W11DevVM.ps1
```

### 5a. Run and save output to a log file (optional)

```powershell
.\Optimize-W11DevVM.ps1 | Tee-Object -FilePath "C:\optimize-log.txt"
```

The log file will be saved at `C:\optimize-log.txt`.

### 6. Reboot

A reboot is recommended after the script finishes to fully apply all changes.

---

## How to revert

To re-enable services and restore registry/CPU settings to Windows defaults:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\Restore-W11DevVM.ps1
```

> **Note:** Apps removed by `Optimize-W11DevVM.ps1` cannot be restored via script.
> Use the Microsoft Store to reinstall them, or use the System Restore point
> that was created automatically before the optimization ran.

---

## Restore point

A System Restore point named **"Before W11 VM Optimization"** is created
automatically at the start of `Optimize-W11DevVM.ps1`.

To access it:

1. Press `Win + R` → type `rstrui` → press Enter
2. Select **"Before W11 VM Optimization"**
3. Follow the wizard
