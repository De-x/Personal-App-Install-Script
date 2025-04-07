<#
.SYNOPSIS
Installs a predefined list of applications on Windows using winget and other specific commands.

.DESCRIPTION
This script automates the installation of several applications.
It uses the winget package manager for most apps and specific commands for others like WSL.
Requires Administrator privileges to run.
Apps not found in winget or without known silent installers are noted for manual installation.

.NOTES
Date:   2025-04-06
Requires: Windows 10 version 1809+ or Windows 11, winget, Administrator privileges.
#>

#Requires -RunAsAdministrator

# --- Script Start ---
Write-Host "Starting application installation script..." -ForegroundColor Yellow

# Check for Administrator privileges (Redundant if #Requires -RunAsAdministrator is effective, but good practice)
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator." -ForegroundColor Red
    # Optional: Attempt to relaunch as admin
    # Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Read-Host "Press Enter to exit."
    Exit 1
} else {
    Write-Host "Running with Administrator privileges." -ForegroundColor Green
}

# --- 1. Winget Application Installs ---
Write-Host "`n--- Installing applications via winget ---" -ForegroundColor Cyan

# List of application IDs for winget
# Find more IDs using: winget search "app name"
$wingetApps = @(
    "Google.Chrome"              # Google Chrome
    "M2Team.NanaZip"             # NanaZip (File Archiver)
    "Valve.Steam"                # Steam (Game Platform)
    "voidtools.Everything"       # Everything Search
    "Microsoft.PowerToys"        # Microsoft PowerToys
    "Notion.Notion"              # Notion (Productivity App)
    "Microsoft.VisualStudioCode" # Visual Studio Code (Code Editor)
    "EpicGames.EpicGamesLauncher"# Epic Games Launcher
    "Stremio.Stremio"            # Stremio (Media Center)
    "Git.Git"                    # Git (Version Control)
    "Discord.Discord"            # Discord (Chat App)
    "HydraLauncher.Hydra"        # Hydra (Game Launcher)
    "Zen-Team.Zen-Browser"       # Zen Browser
    # Add other winget app IDs here if needed
)

# Loop through the list and install each app
foreach ($appId in $wingetApps) {
    Write-Host "Attempting to install $appId ..." -ForegroundColor White
    # Check if the app is already installed (optional, winget often handles this)
    # $installed = winget list --id $appId -n 1 | Select-String $appId
    # if ($installed) {
    #    Write-Host "$appId is already installed." -ForegroundColor Green
    # } else {
        winget install --id $appId --accept-package-agreements --accept-source-agreements --silent
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully installed $appId." -ForegroundColor Green
        } else {
            Write-Warning "Failed to install $appId. Winget exit code: $LASTEXITCODE"
        }
    # }
    Write-Host "----------------------------------------"
}

Write-Host "`n--- Winget installations complete ---" -ForegroundColor Cyan

# --- 2. Windows Subsystem for Linux (WSL) Install ---
Write-Host "`n--- Installing Windows Subsystem for Linux (WSL) ---" -ForegroundColor Cyan
Write-Host "This command will install WSL and the default Ubuntu distribution."
Write-Host "A system reboot might be required after this step." -ForegroundColor Yellow

# Execute the WSL install command
wsl --install # Installs Ubuntu WSL

# Note: Error handling for wsl --install can be complex as it involves Windows features.
# We'll assume it prompts the user or rely on its output messages.
Write-Host "WSL installation command executed. Please follow any on-screen prompts or reboot if required." -ForegroundColor Green

# --- 3. Manual Installation Steps ---
Write-Host "`n--- Manual Installation Required ---" -ForegroundColor Yellow
Write-Host "The following applications could not be automatically installed by this script:"

Write-Host "- MPV:" -ForegroundColor White
Write-Host "  Reason: Not in repositories."
Write-Host "  Action: Please download via other means (e.g. chocolatey)."

# --- Script End ---
Write-Host "`n--- Application installation script finished ---" -ForegroundColor Green
Write-Host "Please check the output above for any errors or required manual steps."
Read-Host "Press Enter to close this window."