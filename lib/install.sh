#!/usr/bin/env bash
# lib/install.sh — Extract a .deb and install Antigravity to APP_DIR

extract_deb() {
  local deb_file="$1"

  log_info "Extracting DEB..."
  bsdtar -xf "$deb_file"
  bsdtar -xf data.tar.xz

  if [[ ! -d usr/share/antigravity ]]; then
    log_error "Unexpected DEB structure: usr/share/antigravity not found."
    return 1
  fi
}

install_binaries() {
  local app_dir="$1"
  local bin_link="$2"

  log_info "Installing into ${app_dir} (requires sudo)..."
  sudo rm -rf "$app_dir"
  sudo mkdir -p "$app_dir"
  sudo cp -r usr/share/antigravity/* "$app_dir/"

  # Chrome/VS Code-style sandbox — must be owned/setuid root
  if [[ -f "${app_dir}/chrome-sandbox" ]]; then
    sudo chown root:root "${app_dir}/chrome-sandbox" || true
    sudo chmod 4755    "${app_dir}/chrome-sandbox" || true
  fi

  log_info "Creating launcher symlink ${bin_link}..."
  sudo mkdir -p "$(dirname "$bin_link")"
  sudo ln -sf "${app_dir}/antigravity" "$bin_link"
  log_ok "Binary installed."
}
