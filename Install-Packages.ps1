$Packages = @(
    @{
        Name       = "7Zip"
        Type       = "msi"
        Source     = "https://www.7-zip.org/a/7z2501-x64.exe"
        SilentArgs = "/qn"
    },
    @{
        Name       = "GoogleChrome"
        Type       = "exe"
        Source     = "https://dl.google.com/chrome/install/375.126/chrome_installer.exe"
        SilentArgs = "/silent /install"
    }
)

param (
    [Parameter(Mandatory = $true)]
    [array]$Packages
)

$ErrorActionPreference = "Stop"
$LogPath = "C:\InstallLogs"
New-Item -ItemType Directory -Path $LogPath -Force | Out-Null

function Install-Package {
    param (
        [string]$Name,
        [string]$Type,          # msi | exe | zip
        [string]$Source,        # URL or local path
        [string]$SilentArgs,    # For exe/msi
        [string]$InstallPath    # For zip extraction
    )

    Write-Host "🔹 Installing $Name..."

    $fileName = Split-Path $Source -Leaf
    $localPath = "C:\Temp\$fileName"
    New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null

    if ($Source -match "^https?://") {
        Write-Host "⬇ Downloading $Name..."
        Invoke-WebRequest -Uri $Source -OutFile $localPath -UseBasicParsing
    } else {
        $localPath = $Source
    }

    switch ($Type.ToLower()) {

        "msi" {
            Start-Process msiexec.exe `
                -ArgumentList "/i `"$localPath`" $SilentArgs /norestart /log `"$LogPath\$Name.log`"" `
                -Wait -NoNewWindow
        }

        "exe" {
            Start-Process $localPath `
                -ArgumentList $SilentArgs `
                -Wait -NoNewWindow
        }

        "zip" {
            if (-not $InstallPath) {
                throw "InstallPath is required for ZIP packages"
            }
            Expand-Archive -Path $localPath -DestinationPath $InstallPath -Force
        }

        default {
            throw "Unsupported package type: $Type"
        }
    }

    Write-Host "✅ $Name installed successfully"
}

foreach ($pkg in $Packages) {
    Install-Package @pkg
}

Write-Host "🎉 All packages installed"

