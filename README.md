# Antigravity Installer (Arch / Garuda / Manjaro / CachyOS)

Unofficial installer for **Google Antigravity** on Arch-based Linux distributions.

> **Forked from [apipa12/antigravity-arch](https://github.com/apipa12/antigravity-arch) by [toxicwind](https://github.com/toxicwind)**  
> This fork fixes a critical bug that caused the installer to always install the *second-to-last* version rather than the latest.

---

## 🐛 Bug Fix (vs upstream)

**Problem:** The awk parser that extracts package info from the APT `Packages` index only committed a record when it encountered a blank line between entries. The **last entry** in the index file has no trailing blank line (EOF), so it was silently dropped — causing the installer to always pick the second-to-last version.

**Fix:** Added an EOF-flush in the awk `END{}` block to capture any in-progress record at end of file.

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

---

## 🇬🇧 Install / Update

### Quick install

```bash
git clone https://github.com/toxicwind/antigravity-arch.git
cd antigravity-arch
chmod +x antigravity-installer.sh
./antigravity-installer.sh
```

### Update in place

```bash
cd antigravity-arch
git pull
./antigravity-installer.sh
```

### Uninstall

```bash
./antigravity-installer.sh --uninstall
```

---

## 📋 Requirements

- `curl`
- `bsdtar` (`libarchive` package)
- `sha256sum` (`coreutils`)
- `awk` (`gawk`)
- `sudo`

```bash
sudo pacman -S curl libarchive coreutils gawk sudo
```

---

## ⚠️ Disclaimer

This installer is **unofficial** and is **not affiliated with or endorsed by Google**.  
Use at your own risk. Always review shell scripts before running them with elevated privileges.

---

## 🛠 Issues

Open an issue: https://github.com/toxicwind/antigravity-arch/issues
