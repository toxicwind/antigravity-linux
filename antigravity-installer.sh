#!/usr/bin/env bash
# antigravity-installer.sh — Antigravity IDE installer for Arch-based Linux
#
# Usage:
#   ./antigravity-installer.sh            # install or update to latest
#   ./antigravity-installer.sh --uninstall
#
# Source: https://github.com/toxicwind/antigravity-arch

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load modules ────────────────────────────────────────────────────────────
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/pkg_index.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/install.sh"
source "${SCRIPT_DIR}/lib/desktop.sh"
source "${SCRIPT_DIR}/lib/uninstall.sh"

# ── Config ──────────────────────────────────────────────────────────────────
APT_BASE="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev"
APP_DIR="/opt/antigravity"
BIN_LINK="/usr/local/bin/antigravity"
DESKTOP1="/usr/share/applications/antigravity.desktop"
DESKTOP2="/usr/share/applications/antigravity-url-handler.desktop"
ICON_PATH="/usr/share/pixmaps/antigravity.png"

# ── Uninstall shortcut ───────────────────────────────────────────────────────
if [[ "${1-}" == "--uninstall" ]]; then
  uninstall "$APP_DIR" "$BIN_LINK" "$DESKTOP1" "$DESKTOP2" "$ICON_PATH"
  exit 0
fi

# ── Requirements ─────────────────────────────────────────────────────────────
for cmd in curl bsdtar sha256sum awk sudo; do
  command -v "$cmd" &>/dev/null || {
    log_error "Required command '$cmd' not found — install it first."
    exit 1
  }
done

# ── Workspace ────────────────────────────────────────────────────────────────
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
cd "$workdir"

# ── Run pipeline ─────────────────────────────────────────────────────────────
fetch_latest_package "Packages" "$APT_BASE"
download_and_verify  "$APT_BASE" "$DEBFILENAME" "$DEBSHA256" "antigravity.deb"
extract_deb          "antigravity.deb"
install_binaries     "$APP_DIR" "$BIN_LINK"
install_desktop_files "$APP_DIR" "$DESKTOP1" "$DESKTOP2" "$ICON_PATH"

echo
log_ok "Antigravity ${DEBVER} installed successfully."
log_info "Run:       antigravity"
log_info "Uninstall: $0 --uninstall"
