<#
.SYNOPSIS
Installs Scoop package manager and a predefined list of applications on Windows using Scoop, Winget, and native commands. Skips apps that are already installed.

.DESCRIPTION
This script automates the installation of the Scoop package manager and several applications.
It checks if apps are already installed via Scoop (globally) or Winget before attempting installation.
It uses Scoop (globally) for specific apps, Winget for many common apps, and specific commands for others (like WSL).
It automatically adds required Scoop buckets (e.g., 'games', 'extras').
Requires Administrator privileges to run for Winget and WSL.

.NOTES
Date:   2025-04-06 (Updated: 2025-04-06)
Requires: Windows 10 version 1809+ or Windows 11, Winget, Internet Connection, Administrator privileges.
#>

#Requires -RunAsAdministrator

# --- Script Start ---
Write-Host "Starting application installation script..." -ForegroundColor Yellow
Write-Host "This script requires Administrator privileges and an internet connection."
Write-Host "It will skip applications that are detected as already installed."

# Check for Administrator privileges
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-NOT $IsAdmin) {
    Write-Error "This script must be run as Administrator (due to Winget/WSL requirements)." -ForegroundColor Red
    Read-Host "Press Enter to exit."
    Exit 1
} else {
    Write-Host "Running with Administrator privileges." -ForegroundColor Green
}

# --- 1. Scoop Installation & Setup ---
Write-Host "`n--- Checking and Installing Scoop Package Manager ---" -ForegroundColor Cyan

# Check if Scoop is already installed
$scoopInstalled = Get-Command scoop -ErrorAction SilentlyContinue
if ($scoopInstalled) {
    Write-Host "Scoop is already installed." -ForegroundColor Green
    # Ensure Scoop paths are in the session's PATH if script is re-run
     if ($env:PATH -notlike "*$env:USERPROFILE\scoop\shims*") { $env:PATH += ";$env:USERPROFILE\scoop\shims" }
     if ($env:PATH -notlike "*C:\ProgramData\scoop\shims*") { $env:PATH += ";C:\ProgramData\scoop\shims" } # For global installs
} else {
    Write-Host "Scoop not found. Attempting to install Scoop..." -ForegroundColor White
    # Set ExecutionPolicy for the current user to allow script execution (required by Scoop installer)
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "Execution policy set for CurrentUser." -ForegroundColor Green

        # Download and run the Scoop installer script
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression -ErrorAction Stop
        Write-Host "Scoop installation script executed." -ForegroundColor Green

        # Add Scoop's directories to the PATH for the current session
        $scoopUserPath = "$env:USERPROFILE\scoop\shims"
        $scoopGlobalPath = "C:\ProgramData\scoop\shims" # Standard global path
        $env:PATH += ";$scoopUserPath"
        $env:PATH += ";$scoopGlobalPath"
        Write-Host "Scoop shim directories added to PATH for this session."

        # Verify installation
        if (Get-Command scoop -ErrorAction SilentlyContinue) {
             Write-Host "Scoop installed successfully." -ForegroundColor Green
             scoop --version
             $scoopInstalled = $true # Set flag to true for later steps
        } else {
             Write-Warning "Scoop installation seems to have failed. Scoop commands might not work."
             $scoopInstalled = $false
        }
    } catch {
        Write-Error "An error occurred during Scoop installation: $($_.Exception.Message)" -ForegroundColor Red
        Write-Warning "Scoop installation failed. Skipping Scoop-related tasks."
        $scoopInstalled = $false
    }
}
Write-Host "----------------------------------------"

# --- 2. Scoop Application Installs ---
Write-Host "`n--- Installing applications via Scoop ---" -ForegroundColor Cyan

# Ensure Scoop command is available before proceeding
if (-not $scoopInstalled) {
    Write-Warning "Scoop command not found or installation failed. Skipping Scoop installations."
} else {
    # Define the list of applications to install via Scoop (as provided by user)
    $scoopApps = @(
        "games/rpcs3"      # PS3 Emulator
        "extras/mpv-git"   # MPV Video Player
        "games/ryujinx"    # Switch Emulator
        "games/dolphin"    # Gamecube Emulator
        # Add other scoop app names here if needed
    )

    # --- Add Required Scoop Buckets ---
    Write-Host "Checking and adding necessary Scoop buckets..." -ForegroundColor White
    $requiredBuckets = $scoopApps | ForEach-Object { if ($_ -match '(.+)/.+') { $Matches[1] } } | Where-Object { $_ -ne $null } | Sort-Object -Unique
    $knownBuckets = scoop bucket known

    foreach ($bucket in $requiredBuckets) {
        if ($knownBuckets -contains $bucket) {
            Write-Host "Bucket '$bucket' is already known." -ForegroundColor Gray
        } else {
            Write-Host "Adding Scoop bucket: $bucket..." -ForegroundColor White
            try {
                scoop bucket add $bucket -ErrorAction Stop
                 Write-Host "Successfully added bucket '$bucket'." -ForegroundColor Green
            } catch {
                 Write-Warning "Failed to add bucket '$bucket'. Apps from this bucket may not install. Error: $($_.Exception.Message)"
            }
        }
    }
    Write-Host "Bucket check complete."
    Write-Host "----------------------------------------"

    # --- Install Scoop Apps ---
    Write-Warning "Running Scoop installs with Administrator privileges."
    Write-Host "Using '--global' flag for Scoop installs to target system-wide directory (C:\ProgramData\scoop)." -ForegroundColor Yellow
    Write-Host "Checking if apps are already installed globally before attempting..." -ForegroundColor Yellow

    # Loop through the list and install each app globally
    foreach ($appName in $scoopApps) {
        Write-Host "Checking Scoop app: '$appName' (global)..." -ForegroundColor White

        # Check if already installed globally
        $isScoopInstalled = $false
        try {
             # Check status, look for the line indicating installation
             # Using Select-String is more reliable than just checking for "Installed" which might appear in descriptions
             $statusOutput = scoop status --global $appName -ErrorAction SilentlyContinue
             if ($statusOutput -match 'Current:') { # 'Current:' usually indicates installed version line
                 $isScoopInstalled = $true
             }
        } catch {
             Write-Warning "Could not determine installation status for '$appName'. Attempting install..."
        }

        if ($isScoopInstalled) {
            Write-Host "'$appName' (global) is already installed. Skipping." -ForegroundColor Blue
        } else {
            Write-Host "Attempting to install '$appName' globally via Scoop..." -ForegroundColor White
            try {
                # Use --global (-g) because we are running as Admin
                scoop install --global $appName -ErrorAction Stop
                Write-Host "Successfully initiated install for '$appName' via Scoop." -ForegroundColor Green
            } catch {
                 Write-Warning "Failed to install '$appName' via Scoop. Error: $($_.Exception.Message)"
            }
        }
        Write-Host "----------------------------------------"
    }
}
Write-Host "`n--- Scoop installations process complete ---" -ForegroundColor Cyan

# --- 3. Winget Application Installs ---
Write-Host "`n--- Installing applications via Winget ---" -ForegroundColor Cyan
Write-Host "Checking if apps are already installed before attempting..." -ForegroundColor Yellow

# List of application IDs for Winget (as provided by user)
$wingetApps = @(
    "Google.Chrome"                 # Google Chrome
    "M2Team.NanaZip"                # NanaZip (File Archiver)
    "Valve.Steam"                   # Steam (Game Platform)
    "voidtools.Everything"          # Everything Search
    "Microsoft.PowerToys"           # Microsoft PowerToys
    "Notion.Notion"                 # Notion (Productivity App)
    "Microsoft.VisualStudioCode"    # Visual Studio Code (Code Editor)
    "EpicGames.EpicGamesLauncher"   # Epic Games Launcher
    "Stremio.Stremio"               # Stremio (Media Center)
    "Git.Git"                       # Git (Version Control)
    "Discord.Discord"               # Discord (Chat App)
    "HydraLauncher.Hydra"           # Hydra (Game Launcher)
    "Zen-Team.Zen-Browser"          # Zen Browser
    "Fedora.FedoraMediaWriter"      # Fedora Media Writer for USBs
    "Ventoy.Ventoy"                 # Bootloader for ISOs
    "Playnite.Playnite"             # Universal Game Launcher
    "PCSX2Team.PCSX2"               # Excellent PS2 Emulator
    "PrismLauncher.PrismLauncher"   # Launcher for Minecraft, mainly modded
    "WinDirStat.WinDirStat"         # Overview of every file in windows
    # Add other winget app IDs here if needed
)

# Loop through the list and install each app
foreach ($appId in $wingetApps) {
    # Skip empty lines if any accidentally added
    if ([string]::IsNullOrWhiteSpace($appId)) { continue }

    Write-Host "Checking Winget package: '$appId'..." -ForegroundColor White

    # Check if already installed using winget list
    $isWingetInstalled = $false
    try {
        # Use -q / --quiet on Select-String for efficiency
        $isWingetInstalled = winget list --id $appId --accept-source-agreements -ErrorAction SilentlyContinue | Select-String -Quiet $appId
    } catch {
         Write-Warning "Could not determine installation status for '$appId'. Attempting install..."
    }

    if ($isWingetInstalled) {
         Write-Host "'$appId' is already installed. Skipping." -ForegroundColor Blue
    } else {
        Write-Host "Attempting to install '$appId' via Winget..." -ForegroundColor White
        # Winget install command
        winget install --id $appId --accept-package-agreements --accept-source-agreements --silent
        $exitCode = $LASTEXITCODE

        # Check results (only relevant if install was attempted)
        if ($exitCode -eq 0) {
            Write-Host "Successfully installed '$appId' via Winget." -ForegroundColor Green
        # Redundant check now, but kept for safety/logging if pre-check fails
        # } elseif ($exitCode -eq 0x8A15000F) {
        #     Write-Host "'$appId' is already installed (detected post-attempt)." -ForegroundColor Blue
        } elseif ($exitCode -eq 0x8A150014) { # Common code for "not found"
             Write-Warning "Winget package not found for ID: '$appId'. Please verify the ID."
        } elseif ($exitCode -ne 0) { # Catch any other non-zero exit code
            # Format exit code as hex for easier searching
            $hexExitCode = "0x{0:X}" -f $exitCode
            Write-Warning "Failed to install '$appId' via Winget. Exit code: $exitCode ($hexExitCode)"
        }
    }
    Write-Host "----------------------------------------"
}
Write-Host "`n--- Winget installations complete ---" -ForegroundColor Cyan

# --- 4. Windows Subsystem for Linux (WSL) Install ---
Write-Host "`n--- Installing Windows Subsystem for Linux (WSL) ---" -ForegroundColor Cyan
# Add a check for WSL? This is complex as 'wsl --status' output varies and WSL might be partially installed.
# Simplest is to let 'wsl --install' handle it, as it often does nothing if already fully installed.
# Consider adding a check if the user frequently re-runs and WSL install is slow/problematic.
# Example rudimentary check (may not be fully reliable):
# $wslStatus = wsl --status -ErrorAction SilentlyContinue
# if ($wslStatus -match 'Default Distribution: Ubuntu' -and $wslStatus -match 'Default Version: 2') {
#    Write-Host "WSL with Ubuntu appears to be installed. Skipping 'wsl --install'." -ForegroundColor Blue
# } else {
    Write-Host "This command will install WSL and the default Ubuntu distribution."
    Write-Host "It may do nothing if WSL is already fully installed."
    Write-Host "A system reboot might be required after this step." -ForegroundColor Yellow

    # Execute the WSL install command
    wsl --install

    Write-Host "WSL installation command executed. Please follow any on-screen prompts or reboot if required." -ForegroundColor Green
# }
Write-Host "----------------------------------------"


# --- 5. Manual Installation Steps ---
Write-Host "`n--- Manual Installation Required ---" -ForegroundColor Yellow
Write-Host "Please review the Winget section above for any packages that were not found (e.g., potentially Zen Browser, Hydra, PCSX2Team)."
Write-Host "Additionally, the following require manual download and installation:"

# Manual apps list as provided by user
Write-Host "- DaVinci Resolve" -ForegroundColor White
Write-Host "  Reason: Not in repositories."
Write-Host "  Action: Click to go to downloads"
Write-Host "  Source: https://www.blackmagicdesign.com/products/davinciresolve"

Write-Host "- Citron" -ForegroundColor White # Assuming this is the intended name (not Citra?)
Write-Host "  Reason: Not in repositories"
Write-Host "  Action: Click to go to downloads"
Write-Host "  Source: https://git.citron-emu.org/Citron/Citron/releases" # User provided link

# Add any other specific manual instructions here

# --- Script End ---
Write-Host "`n--- Application installation script finished ---" -ForegroundColor Green
Write-Host "Review the output above for any errors, required manual steps (especially for Winget 'not found' packages), or necessary reboots."
Read-Host "Press Enter to close this window."
