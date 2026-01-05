# ================================
# Azure VM Software Install Script
# ================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

$TempPath = "C:\Temp"
$LogPath  = "C:\InstallLogs"
$LogFile  = "$LogPath\install.log"

New-Item -ItemType Directory -Path $TempPath -Force | Out-Null
New-Item -ItemType Directory -Path $LogPath  -Force | Out-Null
Start-Transcript -Path $LogFile -Append

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

    Write-Host "Downloading $Name..."
    Invoke-WebRequest -Uri $Source -OutFile $localPath -UseBasicParsing

    $process = Start-Process $localPath `
        -ArgumentList $SilentArgs `
        -Wait `
        -PassThru `
        -NoNewWindow

    if (-not $IgnoreExitCode -and $process.ExitCode -ne 0) {
        throw "$Name installation failed with exit code $($process.ExitCode)"
    }

    # Chrome installs asynchronously — wait
    Start-Sleep -Seconds 15

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

foreach ($pkg in $Packages) {
    Install-Package @pkg
}

Write-Host "All software installed successfully"
Stop-Transcript
