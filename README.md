# SYNOPSIS
Installs Scoop package manager and a predefined list of applications on Windows using Scoop, Winget, and native commands. Skips apps that are already installed.

# DESCRIPTION
This script automates the installation of the Scoop package manager and several applications.
It checks if apps are already installed via Scoop (globally) or Winget before attempting installation.
It uses Scoop (globally) for specific apps, Winget for many common apps, and specific commands for others (like WSL).
It automatically adds required Scoop buckets (e.g., 'games', 'extras').
Requires Administrator privileges to run for Winget and WSL.

# NOTES
Requires: Windows 10 version 1809+ or Windows 11, winget, Administrator privileges, scoop

**Needs this Powershell command**

`Set-ExecutionPolicy Bypass -Scope Process -Force`

Then you need to go into Downloads directory (or wherever you download it) and run the script with

`./installapps.ps1`

# Installs these packages:
1. Chrome
2. Nanazip (7zip fork)
3. Steam
4. Everything Search
5. Powertoys
6. Notion
7. VS Code
8. Epic Games Store
9. Stremio
10. Git
11. Discord
12. Hydra Launcher
13. Zen Broswer
14. WSL Ubuntu
15. Fedora Media Writer
16. Ventoy
17. rpcs3
18. mpv
19. ryujinx
20. dolphin
21. Playnite
22. PCSX2
23. Prism Launcher
24. WinDirStat

Still doesn't install DaVinci Resolve or Citron so those have to be downloaded manually
