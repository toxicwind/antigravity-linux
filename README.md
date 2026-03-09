<div align="center">

<img src="https://raw.githubusercontent.com/toxicwind/antigravity-arch/main/.github/assets/banner.svg" alt="Antigravity Installer" width="100%" />

# antigravity-arch

**Arch Linux installer for Google Antigravity IDE — patched & maintained**

[![Sync Upstream](https://github.com/toxicwind/antigravity-arch/actions/workflows/sync-upstream.yml/badge.svg)](https://github.com/toxicwind/antigravity-arch/actions/workflows/sync-upstream.yml)
[![Fork of apipa12](https://img.shields.io/badge/fork_of-apipa12%2Fantigravity--arch-blue?logo=github)](https://github.com/apipa12/antigravity-arch)
[![Platform](https://img.shields.io/badge/platform-Arch%20%7C%20Garuda%20%7C%20Manjaro%20%7C%20CachyOS-1793D1?logo=archlinux&logoColor=white)](https://archlinux.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

</div>

---

## Why this fork exists

The [upstream installer](https://github.com/apipa12/antigravity-arch) has a silent bug in its `awk` parser: it only commits a package record when it encounters a **blank line** between entries in Google's APT `Packages` index. The **last entry** in the file has no trailing blank line (standard APT behaviour), so it's silently dropped — meaning the installer **always installs the second-to-last version** of Antigravity, no matter how many times you run it.

This fork patches the bug, stays automatically synced with upstream via GitHub Actions, and re-applies the fix as a post-merge step so it can never be silently clobbered by upstream changes.

> If you're on a rolling-release Arch-based distro and want the actual latest Antigravity — this is the one to use.

---

## What's different

| | Upstream (`apipa12`) | This fork (`toxicwind`) |
|---|---|---|
| Latest version installed | ❌ Always one behind | ✅ Correct latest |
| awk EOF flush fix | ❌ Missing | ✅ Applied |
| Auto-sync from upstream | — | ✅ Daily via GitHub Actions |
| Fix survives upstream updates | — | ✅ Re-applied post-merge |

---

## The bug (and the fix)

The awk `END{}` block only prints whatever was saved as `last_*`, but never checks if there's an **in-progress block** at EOF:

```diff
 END{
+  # Flush final block if EOF reached without trailing blank line
+  if (pkg=="antigravity" && ver!="" && file!="" && sha!="") {
+    last_ver=ver; last_file=file; last_sha=sha;
+  }
   if (last_ver && last_file && last_sha)
     print last_ver, last_file, last_sha;
 }
```

---

## Install

```bash
git clone https://github.com/toxicwind/antigravity-arch.git
cd antigravity-arch
chmod +x antigravity-installer.sh
./antigravity-installer.sh
```

The installer will:
- Fetch the latest Antigravity `.deb` from Google APT
- Verify SHA256 checksum
- Install to `/opt/antigravity`
- Create `/usr/local/bin/antigravity` symlink
- Install desktop entry + icon
- Apply Chrome sandbox fix

### Update

```bash
cd antigravity-arch && git pull && ./antigravity-installer.sh
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

## How upstream sync works

A [scheduled GitHub Action](./.github/workflows/sync-upstream.yml) runs daily at 06:00 UTC:

1. Fetches `apipa12/antigravity-arch` → `upstream/main`
2. Merges aggressively — upstream additions and fixes are taken; conflicts resolve in favour of **this fork**
3. Re-applies the awk patch as a post-merge step, even if upstream rewrites that block
4. Pushes the result to `toxicwind/antigravity-arch:main`

You get upstream improvements automatically without losing the fix.

---

## Credits

Original installer and concept by **[@apipa12](https://github.com/apipa12)** — all the heavy lifting of figuring out Google's APT repository structure, sandbox fixes, and cross-distro compatibility is their work. This fork exists solely to fix a version-detection bug and keep things current for CachyOS/Arch users.

---

<div align="center">
<sub>Not affiliated with or endorsed by Google · Use at your own risk</sub>
</div>
