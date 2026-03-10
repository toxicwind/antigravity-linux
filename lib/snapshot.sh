#!/usr/bin/env bash
# lib/snapshot.sh — Transactional state management & backups for Antigravity

create_snapshot() {
    local target_dir="$1"
    local bak_dir="${target_dir}.bak"

    if [ -d "$target_dir" ]; then
        log_info "Creating pre-install snapshot of ${target_dir}..."
        # Atomic preparation: wipe any stale backup first
        sudo -A rm -rf "$bak_dir" 2>/dev/null || true
        # Performance: Use -T (no-target-directory) to prevent recursion into existing bak
        sudo -A cp -rpT "$target_dir" "$bak_dir" || true
        log_ok "Snapshot created: ${bak_dir}"
    fi
}

rollback_snapshot() {
    local target_dir="$1"
    local bak_dir="${target_dir}.bak"
    if [ -d "$bak_dir" ]; then
        log_error "Critical error encountered. Rolling back to previous state..."
        sudo -A rm -rf "$target_dir"
        sudo -A mv "$bak_dir" "$target_dir"
        log_ok "Rollback complete."
    fi
}

commit_snapshot() {
    local target_dir="$1"
    local bak_dir="${target_dir}.bak"
    if [ -d "$bak_dir" ]; then
        sudo -A rm -rf "$bak_dir"
        log_info "Installation committed (snapshot removed)."
    fi
}
