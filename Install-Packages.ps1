# ================================
# Azure VM Software Install Script
# ================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

$TempPath = "C:\Temp"
$LogPath  = "C:\InstallLogs"

New-Item -ItemType Directory -Path $TempPath -Force | Out-Null
New-Item -ItemType Directory -Path $LogPath  -Force | Out-Null

$Packages = @(
    @{
        Name       = "7Zip"
        Source     = "https://www.7-zip.org/a/7z2501-x64.exe"
        SilentArgs = "/S"
        VerifyPath = "C:\Program Files\7-Zip\7z.exe"
    },
    @{
        Name       = "GoogleChrome"
        Source     = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
        SilentArgs = "/silent /install /norestart"
        VerifyPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    }
)

function Install-Package {
    param (
        [string]$Name,
        [string]$Source,
        [string]$SilentArgs,
        [string]$VerifyPath
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

    if ($process.ExitCode -ne 0) {
        throw "$Name installation failed with exit code $($process.ExitCode)"
    }

    if (-not (Test-Path $VerifyPath)) {
        throw "$Name verification failed. File not found: $VerifyPath"
    }

    Write-Host "$Name installed successfully"
}

foreach ($pkg in $Packages) {
    Install-Package @pkg
}

Write-Host "All software installed successfully"
