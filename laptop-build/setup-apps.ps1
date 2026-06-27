# steve-nb1 — Windows 11 application provisioning
# Repo:    aussie4beer/homelab  ->  homelab/laptop-build/setup-apps.ps1
# Host:    steve-nb1 (Acer, ex-pve1; daily driver replacing the Lenovo E15 Gen2)
# Purpose: Batch-install the baseline app set via winget on a fresh Win11 Pro install.
# Usage:   Run as Administrator in PowerShell.
# Note:    Firefox is installed manually before this runs; winget detects and skips it.

$apps = @(
    # Browser
    "Mozilla.Firefox",

    # Security / auth
    "Bitwarden.Bitwarden",
    "Yubico.Authenticator",           # bundles ykman CLI; replaces the EOL YubiKey Manager GUI

    # Dev / IaC
    "Anthropic.Claude",               # Claude desktop app
    "Microsoft.VisualStudioCode",
    "Git.Git",
    "Microsoft.WindowsTerminal",
    "Microsoft.PowerShell",           # PowerShell 7, alongside built-in 5.1

    # Runtimes
    "Microsoft.VCRedist.2015+.x64",
    "Microsoft.DotNet.DesktopRuntime.8",

    # Utilities
    "7zip.7zip",
    "VideoLAN.VLC",
    "Notepad++.Notepad++",

    # Game streaming client
    "MoonlightGameStreamingProject.Moonlight"  # stream from VM 9000 on pve-tank12
)

foreach ($app in $apps) {
    Write-Host "Installing $app ..."
    winget install --id $app --exact --silent --accept-package-agreements --accept-source-agreements
}

Write-Host "Done."
