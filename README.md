<div align="center">

<img src="https://raw.githubusercontent.com/toxicwind/antigravity-linux/main/.github/assets/banner.svg" alt="Antigravity Linux" width="100%"/>

# Antigravity Linux: Silent-Slay Architecture

**High-Performance, Transactional Antigravity IDE Installer for Wayland/Niri**

[![Sync](https://github.com/toxicwind/antigravity-linux/actions/workflows/sync-upstream.yml/badge.svg)](https://github.com/toxicwind/antigravity-linux/actions/workflows/sync-upstream.yml)
[![Test](https://github.com/toxicwind/antigravity-linux/actions/workflows/test.yml/badge.svg)](https://github.com/toxicwind/antigravity-linux/actions/workflows/test.yml)
[![Wayland](https://img.shields.io/badge/Wayland-Native-brightgreen)](https://wayland.freedesktop.org/)
[![Niri](https://img.shields.io/badge/Compositor-Niri-blue)](https://github.com/YaLTeR/niri)

*Silent, atomic, and hardware-accelerated Google Antigravity IDE for the modern Linux desktop. Zero-clutter background updates with full transactional safety.*

[Installation](#installation) · [Architecture](#architecture) · [Features](#features) · [Development](#development)

</div>

---

## The Silent-Slay Advantage

The 2026 update transforms the installer from a simple script into a high-concurrency background engine designed for the "Silent-Slay" workflow:

- **🚀 Concurrent Pipeline** — Parallelizes index fetching, payload download, and environment preparation.
- **🛡️ Transactional Safety** — Atomic snapshots and rollbacks via `lib/snapshot.sh` ensure your IDE never breaks.
- **🎨 Wayland-Native** — Automatic Ozone platform flags injected into launchers for zero-latency Niri/Sway performance.
- **🕶️ Headless Automation** — Zero-prompt updates using the `antigravity-sudo-askpass` agent and `.env` integration.
- **📦 Workspace Bootstrap** — Automatically syncs user extensions and workspace plugins post-upgrade.

---

## Installation

### Quick Start

```bash
git clone https://github.com/toxicwind/antigravity-linux.git ~/.local/share/antigravity-linux
cd ~/.local/share/antigravity-linux
./antigravity-installer.sh
```

### Silent Background Updates

```bash
# Register the background update agent (Silent-Slay)
cp .env.example .env
nano .env # Set your INSTALL_SUDO_PASS
~/.local/bin/antigravity-update-launch &
```

---

## Architecture

### The 2026 Concurrent Pipeline

The orchestrator spawns background jobs to fetch metadata and start the multi-hundred-megabyte payload download as soon as possible, while the main thread prepares the transactional snapshot.

### Module Breakdown

| Module | Purpose |
|---|---|
| `antigravity-installer.sh` | **Concurrent Orchestrator**: Handles background job management. |
| `lib/snapshot.sh` | **State Machine**: Atomically clones `/opt` to `.bak` and handles rollbacks. |
| `lib/install.sh` | **Robust Patching**: Python-based re-serialization of `product.json`. |
| `lib/bootstrap.sh` | **Workspace Sync**: Links dev extensions from `apex-workspace`. |
| `lib/desktop.sh` | **Wayland Injection**: Hardware-accelerates `.desktop` launchers. |

---

## Features

### ✓ Wayland Hardware Acceleration
Launchers are patched with `--ozone-platform-hint=auto` and `--enable-features=WaylandWindowDecorations` for native Wayland behavior on Niri and Sway.

### ✓ Transactional Integrity
If an installation fails mid-way, the `snapshot.sh` module immediately restores the previous known-good state from `/opt/antigravity.bak`. Your dev environment is untouchable.

### ✓ Intelligent JSON Patching
Replaces fragile `sed` logic with a permanent Python-based JSON re-serializer in `lib/install.sh`. Safely removes conflicting API proposals and enforces valid formatting (fixes trailing commas).

### ✓ Headless Sudo Execution
Works with `SUDO_ASKPASS` and `apex-sudo` to provide zero-prompt privilege escalation, making the installer ideal for background updates.

---

## Usage

### Manual Update
```bash
make update
```

### Uninstall (Atomic Removal)
```bash
./antigravity-installer.sh --uninstall
```

---

## Development

### Fast CI Testing
Tests use **bats-core 1.5.0** with mocked system calls.

```bash
make ci     # Lint + CI tests
make test   # Run integration tests
```

---

<div align="center">

**Not affiliated with or endorsed by Google**  
*Antigravity is a trademark of Google LLC*

[Report Issue](https://github.com/toxicwind/antigravity-linux/issues) · [View Source](https://github.com/toxicwind/antigravity-linux)

</div>
