# iLO 4 Configuration — pve-tank12

RIBCL templates and wrapper script for configuring the iLO 4 interface on
`pve-tank12` (iLO at `192.168.1.139`, hostname `ilo-pve-tank12.fosternet.home`).

## Files

| File | Purpose |
|---|---|
| `network.xml.tmpl` | Static IP, hostname (`ilo-pve-tank12`), domain, NTP |
| `global_settings.xml.tmpl` | SSH, session timeout, auth failure logging |
| `server_name.xml.tmpl` | BIOS-visible server name (`pve-tank12`) |
| `users.xml.tmpl` | Administrator account privileges |
| `apply-ilo.sh` | Wrapper — prompts for password, applies all templates |

Templates use `{{ ilo_password }}` as a placeholder. The wrapper substitutes
the value at runtime and pipes XML directly to iLO — nothing is written to disk.

## Usage

Apply all templates (alphabetical order, one password prompt):

```bash
chmod +x apply-ilo.sh
./apply-ilo.sh
```

Apply a single template:

```bash
./apply-ilo.sh network.xml.tmpl
```

Preview substituted XML without sending:

```bash
./apply-ilo.sh --dry-run
```

Override the iLO IP (e.g. during initial setup before DNS is live):

```bash
./apply-ilo.sh --host 192.168.1.139
```

Use Bitwarden CLI to skip the interactive prompt:

```bash
ILO_PASS=$(bw get password "pve-tank12 iLO") ./apply-ilo.sh
```

## SSH legacy algorithm requirements

iLO 4 uses deprecated key exchange algorithms. Add to `~/.ssh/config`:

```
Host 192.168.1.139
    KexAlgorithms +diffie-hellman-group14-sha1
    HostKeyAlgorithms +ssh-rsa
    PubkeyAcceptedKeyTypes +ssh-rsa
```

## Known iLO 4 RIBCL quirks

- Blocks after a syntax error are silently skipped — validate XML before applying.
- Trailing whitespace or content before the XML declaration causes parse failures.
- Use `--data-binary` with curl, not `-d` (which strips newlines).
- NTP settings live inside `MOD_NETWORK_SETTINGS` as `SNTP_SERVER1`/`SNTP_SERVER2`.
- `STATUS_TAG VALUE="0x0000"` in the response means success.

## Hardware reference

- Server: HPE DL380 Gen9
- iLO 4 firmware: 2.82
- System ROM: P89 v3.40
- iLO IP: `192.168.1.139`
- iLO hostname: `ilo-pve-tank12.fosternet.home`
- Server hostname: `pve-tank12.fosternet.home` / `pve-tank12.fosternet.home`
