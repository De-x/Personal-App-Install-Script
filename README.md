# SYNOPSIS
Installs Scoop package manager and a predefined list of applications on Windows using Scoop, Winget, and native commands. Skips apps that are already installed.

# DESCRIPTION
This script automates the installation of the Scoop package manager and several applications.
It checks if apps are already installed via Scoop (globally) or Winget before attempting installation.
It uses Scoop (globally) for specific apps, Winget for many common apps, and specific commands for others (like WSL).
It automatically adds required Scoop buckets (e.g., 'games', 'extras').
Requires Administrator privileges to run for Winget and WSL.

# NOTES
Requires: Windows 10 version 1809+ or Windows 11, winget, Administrator privileges, scoop (will install)

**Needs this Powershell command**

`Set-ExecutionPolicy Bypass -Scope Process -Force`

Then you need to go into Downloads directory and run the script with

`./installapps.ps1`
