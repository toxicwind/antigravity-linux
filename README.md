<div align="center">

<img src="https://raw.githubusercontent.com/toxicwind/antigravity-linux/main/.github/assets/banner.svg" alt="Antigravity Linux" width="100%"/>

# antigravity-linux

**Production-ready Antigravity IDE installer for Arch Linux**

[![Sync](https://github.com/toxicwind/antigravity-linux/actions/workflows/sync-upstream.yml/badge.svg)](https://github.com/toxicwind/antigravity-linux/actions/workflows/sync-upstream.yml)
[![Test](https://github.com/toxicwind/antigravity-linux/actions/workflows/test.yml/badge.svg)](https://github.com/toxicwind/antigravity-linux/actions/workflows/test.yml)
[![Platform](https://img.shields.io/badge/Arch%20%7C%20Garuda%20%7C%20Manjaro%20%7C%20CachyOS-1793D1?logo=archlinux&logoColor=white&label=platform)](https://archlinux.org)
[![License](https://img.shields.io/badge/license-MIT-brightgreen)](LICENSE)

*Seamless Google Antigravity IDE installation on Arch-based systems with automated updates, SHA256 verification, and zero-maintenance deployment.*

[Installation](#installation) · [Features](#features) · [Architecture](#architecture) · [Development](#development)

</div>

---

## Why antigravity-linux?

Google Antigravity doesn't officially support Arch Linux. This installer bridges that gap by:

- **Pulling directly from Google's APT repository** — always gets the authentic latest build
- **Verifying cryptographic integrity** — SHA256 checksums confirmed before installation
- **Handling system integration** — desktop entries, icons, permissions, and sandboxing
- **Staying current automatically** — daily GitHub Actions sync with upstream improvements
- **Providing idempotent operation** — run anytime to update without manual cleanup

No AUR wrappers. No manual dependency hunting. No stale packages.

---

## Installation

### Quick Start

```bash
git clone https://github.com/toxicwind/antigravity-linux.git ~/.local/share/antigravity-linux
cd ~/.local/share/antigravity-linux
./antigravity-installer.sh
```

Launch Antigravity:

```bash
antigravity
```

Or use your application launcher — desktop entries are installed automatically.

### Prerequisites

```bash
sudo pacman -S curl libarchive coreutils gawk sudo python3
```

All packages are standard base-devel components on Arch systems.

---

## Usage

### Update Antigravity

```bash
cd ~/.local/share/antigravity-linux
git pull
./antigravity-installer.sh
```

The installer detects existing installations and performs in-place upgrades.

### Uninstall

```bash
./antigravity-installer.sh --uninstall
```

Removes all binaries, desktop files, and icons completely.

---

## Features

### ✓ Verified Latest Builds

Parses Google's APT Packages index directly to identify the newest release. No hardcoded versions. No lag.

### ✓ Cryptographic Verification

Every download is validated against published SHA256 checksums before extraction. Corrupted or tampered packages are rejected.

### ✓ Complete Desktop Integration

- Application launcher entries (main + URL handler)
- System icons in `/usr/share/pixmaps`
- `antigravity://` URL protocol handling
- Binary symlink at `/usr/local/bin/antigravity`

### ✓ Modular Shell Architecture

```
antigravity-installer.sh → orchestrator (50 lines)
lib/log.sh              → colored logging utilities
lib/pkg_index.sh        → APT index parsing
lib/download.sh         → download + SHA256 verification
lib/install.sh          → extraction, installation, patching
lib/desktop.sh          → desktop file integration
lib/uninstall.sh        → clean removal
```

Each module handles one concern. Source code is readable, testable, and maintainable.

### ✓ Automated Upstream Sync

A GitHub Action runs daily at 06:00 UTC to pull improvements from the upstream Antigravity Arch installer. Local patches are preserved via post-merge hooks — you get the best of both worlds.

### ✓ Idempotent Operation

Run the installer as many times as needed. It detects existing installations, preserves user data, and only updates what changed.

### ✓ Chrome Sandbox Fix

Sets proper ownership and permissions on `chrome-sandbox` binary for Chromium-based security isolation.

---

## Architecture

### Execution Pipeline

```
fetch_latest_package()
       ↓
download_and_verify()
       ↓
extract_deb()
       ↓
install_binaries()
       ↓
install_desktop_files()
```

Each function is independently testable and follows fail-fast error handling with `set -euo pipefail`.

### File Structure

```
antigravity-linux/
├── antigravity-installer.sh    Main orchestrator
├── lib/
│   ├── log.sh                  Logging helpers
│   ├── pkg_index.sh            APT index parsing
│   ├── download.sh             Download + verification
│   ├── install.sh              Binary installation
│   ├── desktop.sh              Desktop integration
│   └── uninstall.sh            Removal logic
├── tests/
│   ├── install.bats            Unit tests (mocked)
│   ├── test_helper.bash        Test utilities
│   └── fixtures/               Test data
└── .github/
    └── workflows/
        ├── test.yml            CI tests
        └── sync-upstream.yml   Daily upstream sync
```

### Installation Locations

| Component | Path |
|-----------|------|
| Binary | `/opt/antigravity/antigravity` |
| Symlink | `/usr/local/bin/antigravity` |
| Desktop files | `/usr/share/applications/` |
| Icon | `/usr/share/pixmaps/antigravity.png` |
| Resources | `/opt/antigravity/resources/` |

---

## Development

### Makefile Targets

```bash
make          # Show all available targets
make ci       # Run lint + CI tests (safe anywhere)
make test     # Run @ci-tagged tests
make test-all # Run all tests including @local
make lint     # Shellcheck all .sh files
make install  # Install or update Antigravity
make verify   # Post-install system checks
make update   # git pull + install
```

### Testing

Tests use [bats-core](https://github.com/bats-core/bats-core) with mocked system calls.

**CI tests** (`@ci`): Run in GitHub Actions with stubbed dependencies  
**Local tests** (`@local`): Require real Arch system with Antigravity installed

```bash
bats tests/install.bats          # Run all tests
bats tests/install.bats --filter "@ci"  # CI tests only
```

See [`VERIFIED.md`](./VERIFIED.md) for confirmed real-system test runs.

---

## How Auto-Sync Works

The [sync-upstream workflow](.github/workflows/sync-upstream.yml) maintains this fork with upstream improvements:

1. **Fetch** — Pulls latest changes from `apipa12/antigravity-arch`
2. **Merge** — Integrates improvements automatically
3. **Post-merge hook** — Re-applies local patches for compatibility
4. **Commit** — Pushes merged result to main branch

Runs daily at 06:00 UTC. No manual intervention required.

---

## Troubleshooting

### Installer fails with "command not found"

Install missing dependencies:

```bash
sudo pacman -S curl libarchive coreutils gawk sudo python3
```

### Antigravity won't launch

Check binary exists and is executable:

```bash
ls -la /opt/antigravity/antigravity
/usr/local/bin/antigravity --version
```

### Desktop entry not appearing

Refresh desktop database:

```bash
update-desktop-database ~/.local/share/applications
```

### Permission denied errors

Ensure sudo is configured and SUDO_ASKPASS is set for GUI password prompts.

---

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Write tests for new functionality
4. Ensure `make ci` passes
5. Submit a pull request

---

## Acknowledgements

Based on [apipa12/antigravity-arch](https://github.com/apipa12/antigravity-arch) — the original Arch installer for Google Antigravity. This fork extends it with modular architecture, automated sync, comprehensive testing, and enhanced reliability.

Upstream improvements are merged automatically via GitHub Actions.

---

## License

MIT License — see [LICENSE](./LICENSE) for details.

---

<div align="center">

**Not affiliated with or endorsed by Google**  
*Antigravity is a trademark of Google LLC*

[Report Issue](https://github.com/toxicwind/antigravity-linux/issues) · [View Source](https://github.com/toxicwind/antigravity-linux)

</div>
