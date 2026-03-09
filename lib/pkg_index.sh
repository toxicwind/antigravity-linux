#!/usr/bin/env bash
# lib/pkg_index.sh — Fetch and parse the Google APT Packages index
# Exports: DEBVER, DEBFILENAME, DEBSHA256

fetch_latest_package() {
  local packages_file="$1"
  local apt_base="$2"
  local index_url="${apt_base}/dists/antigravity-debian/main/binary-amd64/Packages"

  log_info "Fetching APT Packages index..."
  curl -fsSL "$index_url" -o "$packages_file"

  log_info "Parsing latest antigravity entry..."
  read -r DEBVER DEBFILENAME DEBSHA256 <<< "$(
    awk '
      BEGIN { pkg=""; ver=""; file=""; sha=""; last_ver=""; last_file=""; last_sha=""; }
      /^Package: antigravity$/ { pkg="antigravity"; ver=""; file=""; sha=""; next; }
      pkg=="antigravity" && /^Version:/  { ver=$2  }
      pkg=="antigravity" && /^Filename:/ { file=$2 }
      pkg=="antigravity" && /^SHA256:/   { sha=$2  }
      NF==0 && pkg=="antigravity" && ver!="" && file!="" && sha!="" {
        last_ver=ver; last_file=file; last_sha=sha; pkg="";
      }
      END {
        # Flush final block — APT Packages index has no trailing blank line
        if (pkg=="antigravity" && ver!="" && file!="" && sha!="") {
          last_ver=ver; last_file=file; last_sha=sha;
        }
        if (last_ver && last_file && last_sha)
          print last_ver, last_file, last_sha;
      }
    ' "$packages_file"
  )"

  if [[ -z "${DEBVER:-}" || -z "${DEBFILENAME:-}" || -z "${DEBSHA256:-}" ]]; then
    log_error "Failed to parse antigravity package info from Packages index"
    return 1
  fi

  log_ok "Latest version : $DEBVER"
  log_ok "Filename       : $DEBFILENAME"
  log_ok "SHA256         : $DEBSHA256"
  export DEBVER DEBFILENAME DEBSHA256
}
