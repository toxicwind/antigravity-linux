<div align="center">

<img src="https://raw.githubusercontent.com/toxicwind/antigravity-linux/main/.github/assets/banner.svg" alt="" width="100%"/>

# antigravity-linux

**The definitive Antigravity IDE installer for Arch-based Linux**

[![Sync](https://github.com/toxicwind/antigravity-linux/actions/workflows/sync-upstream.yml/badge.svg)](https://github.com/toxicwind/antigravity-linux/actions/workflows/sync-upstream.yml)
[![Test](https://github.com/toxicwind/antigravity-linux/actions/workflows/test.yml/badge.svg)](https://github.com/toxicwind/antigravity-linux/actions/workflows/test.yml)
[![Platform](https://img.shields.io/badge/Arch%20%7C%20Garuda%20%7C%20Manjaro%20%7C%20CachyOS-1793D1?logo=archlinux&logoColor=white&label=platform)](https://archlinux.org)
[![Shell](https://img.shields.io/badge/bash-modular-89e051?logo=gnubash&logoColor=white)](./lib)
[![License](https://img.shields.io/badge/license-MIT-brightgreen)](LICENSE)

</div>

---

## Overview

`antigravity-linux` is a clean, modular shell installer that pulls the **verified latest build** of [Google Antigravity](https://antigravity.google) directly from Google's official APT repository and installs it properly on Arch-based systems — something the official release pipeline doesn't provide.

It is idempotent, SHA256-verified, and auto-syncs with upstream installer improvements daily via GitHub Actions.

---

## Features

| | |
|---|---|
| 🎯 **Always latest** | Parses the APT index correctly — gets the actual newest build every time |
| 🔐 **SHA256 verified** | Checksum confirmed before anything touches your system |
| 🧩 **Modular** | Clean `lib/` architecture — each concern is its own sourced module |
| 🔄 **Auto-synced** | Daily GitHub Action pulls upstream improvements without overwriting local fixes |
| 🖥️ **Desktop integrated** | `.desktop` launcher, icon, and URL handler installed automatically |
| ⚙️ **Sandbox ready** | Chrome-style `chrome-sandbox` setuid fix applied on install |
| ♻️ **Idempotent** | Re-run anytime to update — no manual cleanup needed |

---

## Install

```bash
git clone https://github.com/toxicwind/antigravity-linux.git
cd antigravity-linux
chmod +x antigravity-installer.sh
./antigravity-installer.sh
```

Then just run:

```bash
antigravity
```

### Update

```bash
cd antigravity-linux && git pull && ./antigravity-installer.sh
```

### Uninstall

```bash
./antigravity-installer.sh --uninstall
```

---

## Requirements

```bash
sudo pacman -S curl libarchive coreutils gawk sudo
```

---

## Architecture

```
antigravity-linux/
├── antigravity-installer.sh   # thin orchestrator (~50 lines)
└── lib/
    ├── log.sh                 # coloured logging helpers
    ├── pkg_index.sh           # APT Packages index fetch + parse
    ├── download.sh            # .deb download + SHA256 verify
    ├── install.sh             # extraction, binary install, sandbox fix
    ├── desktop.sh             # .desktop entries + icon
    └── uninstall.sh           # clean removal
```

The installer is a single-responsibility pipeline:

```
fetch_latest_package → download_and_verify → extract_deb → install_binaries → install_desktop_files
```

---

## How auto-sync works

A [scheduled GitHub Action](./.github/workflows/sync-upstream.yml) runs daily at 06:00 UTC. It fetches the latest upstream installer improvements, merges them, then re-applies any local patches as a post-merge step — so upstream updates land automatically without breaking anything.

---

## Acknowledgements

Based on [apipa12/antigravity-arch](https://github.com/apipa12/antigravity-arch) — the original Arch installer for Antigravity. This fork extends it with a modular architecture, version-detection fix, and automated CI. All upstream improvements are pulled in daily.

---

## License

MIT — see [LICENSE](./LICENSE)


---

<div align="center">
<sub>Not affiliated with or endorsed by Google · Antigravity is a trademark of Google LLC</sub>
</div>
