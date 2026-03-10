#!/usr/bin/env bash
# lib/desktop.sh — Install .desktop launchers and application icon

install_desktop_files() {
  local app_dir="$1"
  local desktop1="$2"
  local desktop2="$3"
  local icon_path="$4"

  log_info "Installing .desktop entries..."

  if [[ -f usr/share/applications/antigravity.desktop ]]; then
    local tmp1
    tmp1="$(mktemp)"
    sed "s|^Exec=.*|Exec=${app_dir}/antigravity %U|g" \
      usr/share/applications/antigravity.desktop > "$tmp1"
    sudo -A install -Dm644 "$tmp1" "$desktop1"
  fi

  if [[ -f usr/share/applications/antigravity-url-handler.desktop ]]; then
    local tmp2
    tmp2="$(mktemp)"
    sed "s|^Exec=.*|Exec=${app_dir}/antigravity %U|g" \
      usr/share/applications/antigravity-url-handler.desktop > "$tmp2"
    sudo -A install -Dm644 "$tmp2" "$desktop2"
  fi

  log_info "Installing icon..."
  if [[ -f usr/share/pixmaps/antigravity.png ]]; then
    sudo -A install -Dm644 usr/share/pixmaps/antigravity.png "$icon_path"
  fi

  log_ok "Desktop integration complete."
}
