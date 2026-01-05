$Packages = @(
    @{
        Name       = "7Zip"
        Type       = "msi"
        Source     = "https://www.7-zip.org/a/7z2301-x64.msi"
        SilentArgs = "/qn"
    },
    @{
        Name       = "GoogleChrome"
        Type       = "exe"
        Source     = "https://dl.google.com/chrome/install/375.126/chrome_installer.exe"
        SilentArgs = "/silent /install"
    },
    @{
        Name        = "CustomTool"
        Type        = "zip"
        Source      = "https://example.com/tools/customtool.zip"
        InstallPath = "C:\Tools\CustomTool"
    }
)

.\Install-Packages.ps1 -Packages $Packages
