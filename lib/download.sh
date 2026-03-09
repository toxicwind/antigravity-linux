#!/usr/bin/env bash
# lib/download.sh — Download and verify a Antigravity .deb package

download_and_verify() {
  local apt_base="$1"
  local filename="$2"   # e.g. pool/antigravity-debian/antigravity_1.20.4_amd64.deb
  local expected_sha="$3"
  local out_file="$4"   # destination path

  local url="${apt_base}/${filename}"

  log_info "Downloading from:"
  log_info "  $url"
  curl -fsSL "$url" -o "$out_file"

  log_info "Verifying SHA256..."
  echo "${expected_sha}  ${out_file}" | sha256sum -c - || {
    log_error "SHA256 mismatch — aborting"
    return 1
  }
  log_ok "Checksum verified."
}
