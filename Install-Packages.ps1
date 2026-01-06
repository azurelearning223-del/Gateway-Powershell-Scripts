# ================================
# Azure VM Software Install Script
# ================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

# Paths
$TempPath = "C:\Temp"
$LogPath  = "C:\InstallLogs"
$LogFile  = "$LogPath\install.log"

# Ensure directories exist
New-Item -ItemType Directory -Path $TempPath -Force | Out-Null
New-Item -ItemType Directory -Path $LogPath  -Force | Out-Null
Start-Transcript -Path $LogFile -Append

# Disable IE First Run Prompt (helps Invoke-WebRequest)
reg add "HKLM\SOFTWARE\Microsoft\Internet Explorer\Main" `
  /v DisableFirstRunCustomize /t REG_DWORD /d 1 /f | Out-Null

# Packages to install
$Packages = @(
    @{
        Name       = "7Zip"
        Source     = "https://www.7-zip.org/a/7z2501-x64.exe"
        SilentArgs = "/S"
        VerifyPath = @("C:\Program Files\7-Zip\7z.exe")
        IgnoreExitCode = $false
    },
    @{
        Name       = "GoogleChrome"
        Source     = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
        SilentArgs = "/silent /install /norestart"
        VerifyPath = @(
            "C:\Program Files\Google\Chrome\Application\chrome.exe",
            "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        )
        IgnoreExitCode = $true
    }
)

# Function to install a package
function Install-Package {
    param (
        [string]$Name,
        [string]$Source,
        [string]$SilentArgs,
        [array] $VerifyPath,
        [bool]  $IgnoreExitCode
    )

    Write-Host "Installing $Name..."
    $fileName  = Split-Path $Source -Leaf
    $localPath = Join-Path $TempPath $fileName

    # Download with retry
    $retry = 0
    $success = $false
    do {
        try {
            Write-Host "Downloading $Name..."
            Invoke-WebRequest -Uri $Source -OutFile $localPath -UseBasicParsing
            $success = $true
        } catch {
            $retry++
            Write-Host "Download failed, retry $retry/3..."
            Start-Sleep -Seconds 10
        }
    } until ($success -or $retry -ge 3)

    if (-not $success) {
        throw "Failed to download $Name after 3 attempts"
    }

    # Install
    $process = Start-Process $localPath `
        -ArgumentList $SilentArgs `
        -Wait `
        -PassThru `
        -NoNewWindow

    # Accept exit code 0 or 3010 (reboot required)
    if (-not $IgnoreExitCode -and $process.ExitCode -notin @(0,3010)) {
        throw "$Name installation failed with exit code $($process.ExitCode)"
    }

    # Wait a few seconds for async installers
    Start-Sleep -Seconds 15

    # Verification
    $found = $false
    foreach ($path in $VerifyPath) {
        if (Test-Path $path) {
            $found = $true
            break
        }
    }

    if (-not $found) {
        throw "$Name verification failed. Executable not found."
    }

    Write-Host "$Name installed successfully"
}

# Install all packages
foreach ($pkg in $Packages) {
    Install-Package @pkg
}

Write-Host "All software installed successfully"
Stop-Transcript
