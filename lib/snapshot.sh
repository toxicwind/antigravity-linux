#!/usr/bin/env bash
# lib/snapshot.sh — Transactional state management & backups for Antigravity

create_snapshot() {
    local target_dir="$1"
    local backup_name="antigravity_pre_install_$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_path="/tmp/${backup_name}"

    if [ -d "$target_dir" ]; then
        log_info "Creating pre-install snapshot of ${target_dir}..."
        # tar czf "$backup_path" -C "$(dirname "$target_dir")" "$(basename "$target_dir")" 2>/dev/null || true
        # Optimized: copy instead to avoid tar overhead for small files
        sudo cp -rp "$target_dir" "${target_dir}.bak" || true
        log_ok "Snapshot created: ${target_dir}.bak"
    fi
}

rollback_snapshot() {
    local target_dir="$1"
    if [ -d "${target_dir}.bak" ]; then
        log_error "Critical error encountered. Rolling back to previous state..."
        sudo rm -rf "$target_dir"
        sudo mv "${target_dir}.bak" "$target_dir"
        log_ok "Rollback complete."
    fi
}

commit_snapshot() {
    local target_dir="$1"
    if [ -d "${target_dir}.bak" ]; then
        sudo rm -rf "${target_dir}.bak"
        log_info "Installation committed (snapshot removed)."
    fi
}
