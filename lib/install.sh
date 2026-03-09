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

  # ── 3. Apply Permanent JSON Patches ─────────────────────────────────────────

  local product_json="${app_dir}/resources/app/product.json"
  local package_json="${app_dir}/resources/app/package.json"

  # Helper function for robust JSON manipulation
  patch_json_robust() {
    local target="$1"
    [[ ! -f "$target" ]] && return 0
    
    log_info "Applying permanent patches to $(basename "$target")..."
    sudo python3 - <<EOF
import json
import sys
import re

path = "$target"
try:
    with open(path, 'r') as f:
        content = f.read()
    
    # Pre-process to fix existing corruption if present (e.g. random commas)
    clean = re.sub(r',\s*([\]}])', r'\1', content)
    clean = re.sub(r',\s*,', r',', clean)
    
    try:
        data = json.loads(clean)
    except json.JSONDecodeError as e:
        print(f"[!] Critical JSON error in {path}: {e}")
        sys.exit(1)
    
    modified = False
    
    # Logic for product.json
    if "product.json" in path:
        proposals = data.get("extensionEnabledApiProposals", {})
        to_remove = [
            "attributableCoverage", "notebookCellExecutionState", 
            "contribIssueReporter", "fileComments", "chatVariableResolver", 
            "lmTools", "documentPaste"
        ]
        for p in to_remove:
            if p in proposals:
                del proposals[p]
                modified = True
                
    # Add any package.json specific logic here if needed, 
    # or just use this pass to ensure it's linted/prettified.
    if "package.json" in path:
        # Example: Ensure certain scripts or flags are set
        pass

    if modified:
        with open(path, 'w') as f:
            json.dump(data, f, indent=4)
        print(f"[*] Patched {path} successfully.")
    else:
        # Even if not modified by logic, we re-save to ensure it's "linted" by python
        with open(path, 'w') as f:
            json.dump(data, f, indent=4)
        print(f"[*] Verified/Re-serialized {path}.")
        
except Exception as e:
    print(f"[!] Error during JSON patching: {e}")
    sys.exit(1)
EOF
    # Validation
    if ! python3 -m json.tool "$target" > /dev/null 2>&1; then
        log_error "CRITICAL: $(basename "$target") is invalid! Installation may be unstable."
        return 1
    fi
  }

  patch_json_robust "$product_json" || return 1
  patch_json_robust "$package_json" || return 1

  # Patch UI branding
  patch_ui() {
    local target_app_dir="$1"
    local auth_page="${target_app_dir}/resources/app/extensions/antigravity/auth-success-jetski.html"
    [[ ! -f "$auth_page" ]] && return 0
    
    log_info "Applying branding to auth success page..."
    sudo sed -i 's/<title>Authentication Successful<\/title>/<title>Redirecting to Antigravity<\/title>/g' "$auth_page"
    sudo sed -i 's/Sign in successful. Redirecting to Jetski.../Blast off! Redirecting to Jetski.../g' "$auth_page"
  }
  patch_ui "$app_dir"

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
