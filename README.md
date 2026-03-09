# Antigravity Installer (Arch / Garuda / Manjaro / CachyOS)

> **Fork of [apipa12/antigravity-arch](https://github.com/apipa12/antigravity-arch)** — maintained by [toxicwind](https://github.com/toxicwind)
>
> Credit and original work goes to **[@apipa12](https://github.com/apipa12)**. This fork applies bug fixes and maintains compatibility with the latest Antigravity builds. Upstream changes are merged automatically via GitHub Actions.

---

## 🐛 Changes vs Upstream

### Fix: awk always installed second-to-last version ([`antigravity-installer.sh`](./antigravity-installer.sh))

The awk parser that reads the APT `Packages` index only committed a package record when it hit a blank separator line (`NF==0`). The **last entry** in the file has no trailing blank line (EOF), so it was always silently dropped — causing the installer to pick the second-to-last version every time.

**Fix:** Added an EOF flush in the `END{}` block:

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

## ✨ Features

- ✅ Fetches the **latest Antigravity build** directly from Google APT
- ✅ Verifies integrity via **SHA256 checksum**
- ✅ Installs binaries into **`/opt/antigravity`**
- ✅ Creates a **`/usr/local/bin/antigravity`** launcher symlink
- ✅ Installs **.desktop launcher** and application icon
- ✅ Applies **Chrome-style sandbox** fix for better compatibility
- ✅ **Idempotent:** re-running updates Antigravity to the latest version
- ✅ **Auto-synced** from upstream via GitHub Actions (without clobbering fixes)

---

## 🇬🇧 Install / Update

```bash
git clone https://github.com/toxicwind/antigravity-arch.git
cd antigravity-arch
chmod +x antigravity-installer.sh
./antigravity-installer.sh
```

To update later:

```bash
cd antigravity-arch && git pull && ./antigravity-installer.sh
```

```bash
./antigravity-installer.sh --uninstall
```

---

## 📋 Requirements

```bash
sudo pacman -S curl libarchive coreutils gawk sudo
```

---

## ⚠️ Disclaimer

This installer is **unofficial** and **not affiliated with or endorsed by Google**.  
Use at your own risk. Always review scripts before running with elevated privileges.

---

## 🔗 Upstream

- Original repo: https://github.com/apipa12/antigravity-arch
- Issues / PRs for this fork: https://github.com/toxicwind/antigravity-arch/issues
