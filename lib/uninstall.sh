#!/usr/bin/env bash
# lib/uninstall.sh — Remove Antigravity files installed by this script

uninstall() {
  local app_dir="$1"
  local bin_link="$2"
  local desktop1="$3"
  local desktop2="$4"
  local icon_path="$5"

  log_info "Uninstalling Antigravity..."
  sudo -A rm -rf  "$app_dir"           || true
  sudo -A rm -f   "$bin_link"          || true
  sudo -A rm -f   "$desktop1" "$desktop2" || true
  sudo -A rm -f   "$icon_path"         || true
  log_ok "Antigravity removed."
}
