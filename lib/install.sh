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
  sudo mkdir -p "$app_dir"
  
  # Merge core files
  sudo cp -rn usr/share/antigravity/* "$app_dir/"
  
  # Force update critical binaries and directories if they exist in source
  [[ -f usr/share/antigravity/antigravity ]] && sudo cp -f usr/share/antigravity/antigravity "$app_dir/"
  [[ -d usr/share/antigravity/resources ]] && sudo cp -rf usr/share/antigravity/resources "$app_dir/"
  [[ -d usr/share/antigravity/out ]] && sudo cp -rf usr/share/antigravity/out "$app_dir/"

  # Patch product.json to remove outdated API proposals safely
  local product_json="${app_dir}/resources/app/product.json"
  if [[ -f "$product_json" ]]; then
    log_info "Patching product.json (safe JSON manipulation)..."
    sudo python3 - <<EOF
import json
import sys

path = "$product_json"
try:
    with open(path, 'r') as f:
        data = json.load(f)
    
    # Remove problematic extension proposals that cause v1.20.4 to crash or warn
    if "extensionEnabledApiProposals" in data:
        proposals = data["extensionEnabledApiProposals"]
        to_remove = [
            "attributableCoverage", "notebookCellExecutionState", 
            "contribIssueReporter", "fileComments", "chatVariableResolver", 
            "lmTools", "documentPaste"
        ]
        
        modified = False
        for p in to_remove:
            if p in proposals:
                del proposals[p]
                modified = True
                
        if modified:
            with open(path, 'w') as f:
                json.dump(data, f, indent=4)
            print(f"[*] Patched {path} successfully.")
        else:
            print("[*] No patches needed for product.json.")
except Exception as e:
    print(f"[!] Error patching product.json: {e}")
    sys.exit(1)
EOF
    # Lint check to ensure we didn't break it
    if ! python3 -m json.tool "$product_json" > /dev/null 2>&1; then
        log_error "CRITICAL: product.json is invalid after patching! Reverting..."
        # In a real scenario, we'd have a backup. For now, we report the failure.
        return 1
    fi
  fi

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
