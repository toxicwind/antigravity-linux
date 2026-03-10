#!/usr/bin/env bash
# lib/bootstrap.sh — Extension & Plugin bootstrapping for Antigravity (Task 9)

bootstrap_extensions() {
    local ext_dir="${HOME}/.antigravity/extensions"
    log_info "Bootstrapping extensions in ${ext_dir}..."

    mkdir -p "$ext_dir"
    
    # Concurrent pattern: check for common extensions in workspace
    # and link them if present to avoid redundant downloads
    local workspace_exts="${HOME}/apex-workspace/extensions"
    if [ -d "$workspace_exts" ]; then
        for ext in "$workspace_exts"/*; do
            if [ -d "$ext" ]; then
                ln -sf "$ext" "$ext_dir/"
                log_ok "Linked extension: $(basename "$ext")"
            fi
        done
    fi
}
