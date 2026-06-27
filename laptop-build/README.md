# steve-nb1 — Laptop Provisioning

Windows 11 Pro provisioning for `steve-nb1` (Acer, ex-`pve1`; daily driver
replacing the failed Lenovo E15 Gen2). Covers baseline app install via winget
and post-install WSL setup for Claude Code.

## Prerequisites

| Requirement | Notes |
|---|---|
| Clean Windows 11 Pro install | TPM 2.0 required; must be satisfied before setup |
| Firefox installed manually | Install from mozilla.org before running the script; winget detects and skips it |
| winget present | Ships with Win11; verify with `winget --version` in a terminal |
| Administrator PowerShell | Required for winget silent installs and execution policy override |

## How to run

Open PowerShell as Administrator, then:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd C:\path\to\laptop-build
.\setup-apps.ps1
```

The script installs each app sequentially. If a package is already present
winget skips it cleanly.

## What installs

| Package ID | What it is |
|---|---|
| `Mozilla.Firefox` | Browser (likely already present — winget skips) |
| `Bitwarden.Bitwarden` | Password manager |
| `Yubico.Authenticator` | FIDO2 / TOTP authenticator; bundles `ykman` CLI |
| `Anthropic.Claude` | Claude desktop app |
| `Microsoft.VisualStudioCode` | Editor |
| `Git.Git` | Git for Windows |
| `Microsoft.WindowsTerminal` | Modern terminal |
| `Microsoft.PowerShell` | PowerShell 7 (runs alongside built-in 5.1) |
| `Microsoft.VCRedist.2015+.x64` | Visual C++ runtime |
| `Microsoft.DotNet.DesktopRuntime.8` | .NET 8 desktop runtime |
| `7zip.7zip` | Archive utility |
| `VideoLAN.VLC` | Media player |
| `Notepad++.Notepad++` | Text editor |
| `MoonlightGameStreamingProject.Moonlight` | Game streaming client (VM 9000 on pve-tank12) |

## Post-install: WSL and Claude Code

Claude Code runs inside WSL, not on Windows directly.

**1. Install WSL without a default distro:**

```powershell
wsl --install --no-distribution
```

Reboot when prompted.

**2. Import the Ubuntu distro from the OneDrive export tar:**

```powershell
wsl --import Ubuntu C:\WSL\Ubuntu C:\path\to\ubuntu-export.tar
```

Adjust paths to match where OneDrive synced the export tar.

**3. Install Claude Code inside Ubuntu:**

```bash
wsl -d Ubuntu
curl -fsSL https://claude.ai/install.sh | bash
```

Claude Code is then available as `claude` inside the WSL shell.

## Important

- `Anthropic.Claude` (desktop app) and Claude Code both ship a `claude.exe`
  on the Windows PATH. Keep Claude Code inside WSL to avoid the collision;
  do not install it via winget on Windows.
- winget packages do not auto-update. Run `winget upgrade --all` periodically
  to pull in new versions.
- FIDO operations (YubiKey, Windows Hello management) require an elevated
  (Administrator) prompt.
