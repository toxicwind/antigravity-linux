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
[[ -f "${SCRIPT_DIR}/.env" ]] && source "${SCRIPT_DIR}/.env"

# ── Load modules ────────────────────────────────────────────────────────────
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/snapshot.sh"
source "${SCRIPT_DIR}/lib/pkg_index.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/install.sh"
source "${SCRIPT_DIR}/lib/desktop.sh"
source "${SCRIPT_DIR}/lib/uninstall.sh"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

# ── Config ──────────────────────────────────────────────────────────────────
APT_BASE="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev"
APP_DIR="/opt/antigravity"
BIN_LINK="/usr/local/bin/antigravity"
DESKTOP1="/usr/share/applications/antigravity.desktop"
DESKTOP2="/usr/share/applications/antigravity-url-handler.desktop"
ICON_PATH="/usr/share/pixmaps/antigravity.png"

# ── Env & Sudo Setup ─────────────────────────────────────────────────────────
export SUDO_ASKPASS="/home/toxic/.local/bin/antigravity-sudo-askpass"

# ── Modular Orchestration ────────────────────────────────────────────────────
main() {
  if [[ "${1-}" == "--uninstall" ]]; then
    uninstall "$APP_DIR" "$BIN_LINK" "$DESKTOP1" "$DESKTOP2" "$ICON_PATH"
    exit 0
  fi

  # 1. Synchronize (Task 4/6)
  log_info "Synchronizing with upstream repositories..."
  fetch_latest_package "Packages" "$APT_BASE"

  # 2. Transactional safety (Task 5)
  create_snapshot "$APP_DIR"

  # 3. Parallel Execution (Task 6)
  local workdir="$(mktemp -d)"
  trap 'rm -rf "$workdir"' EXIT
  
  log_info "Launching concurrent payload fetch..."
  ( cd "$workdir" && download_and_verify "$APT_BASE" "$DEBFILENAME" "$DEBSHA256" "antigravity.deb" ) & 
  local DOWNLOAD_PID=$!

  # concurrent checks
  for cmd in bsdtar sha256sum awk sudo; do
    command -v "$cmd" &>/dev/null || { log_error "Required command '$cmd' not found."; rollback_snapshot "$APP_DIR"; exit 1; }
  done

  wait $DOWNLOAD_PID || { log_error "Payload download failed."; rollback_snapshot "$APP_DIR"; exit 1; }

  # 4. Atomic installation
  cd "$workdir"
  extract_deb          "antigravity.deb" || { rollback_snapshot "$APP_DIR"; exit 1; }
  install_binaries     "$APP_DIR" "$BIN_LINK" || { rollback_snapshot "$APP_DIR"; exit 1; }
  install_desktop_files "$APP_DIR" "$DESKTOP1" "$DESKTOP2" "$ICON_PATH"
  bootstrap_extensions || true
  
  commit_snapshot "$APP_DIR"
  log_ok "Installation concurrent pipeline complete."
  log_info "Version: ${DEBVER}"
}

main "$@"
