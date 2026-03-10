#!/usr/bin/env bats
# tests/install.bats — tests for lib/install.sh
bats_require_minimum_version 1.5.0
# bats file_tags=ci

load 'test_helper'

setup() {
  setup_mocks
  source_lib log.sh
  source_lib install.sh
  WORKDIR="$(mktemp -d)"
}

teardown() {
  teardown_mocks
  rm -rf "$WORKDIR"
}

# ── extract_deb ──────────────────────────────────────────────────────────────

@test "extract_deb succeeds when usr/share/antigravity exists" {
  # Stub bsdtar to create the expected directory structure
  make_stub bsdtar "mkdir -p usr/share/antigravity"
  cd "$WORKDIR"
  run extract_deb "fake.deb"
  [ "$status" -eq 0 ]
}

@test "extract_deb fails when usr/share/antigravity missing after extraction" {
  make_stub bsdtar "exit 0"  # succeeds but creates nothing
  cd "$WORKDIR"
  run extract_deb "fake.deb"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unexpected DEB structure"* ]]
}

# ── install_binaries ─────────────────────────────────────────────────────────

@test "install_binaries calls sudo to copy files and creates symlink" {
  # Setup fake source dir
  mkdir -p "${WORKDIR}/usr/share/antigravity"
  touch "${WORKDIR}/usr/share/antigravity/antigravity"
  cd "$WORKDIR"

  local sudo_calls="${WORKDIR}/sudo_calls"
  make_stub sudo "echo \"\$@\" >> '${sudo_calls}'"

  run install_binaries "/opt/antigravity-test" "/usr/local/bin/antigravity-test"
  [ "$status" -eq 0 ]
  grep -q "cp -r" "$sudo_calls"
  grep -q "ln -sf" "$sudo_calls"
}

@test "install_binaries applies setuid to chrome-sandbox when present" {
  local APP_DIR="${WORKDIR}/opt/ag"
  mkdir -p "${WORKDIR}/usr/share/antigravity"
  touch "${WORKDIR}/usr/share/antigravity/antigravity"

  local sudo_calls="${WORKDIR}/sudo_calls"
  # Stub sudo: for the cp step, also seed chrome-sandbox into APP_DIR so the
  # [[ -f ]] check in install_binaries sees it after 'sudo cp' runs.
  # Stub sudo: handle -A if present
  make_stub sudo "
    if [[ \"\$1\" == '-A' ]]; then shift; fi
    echo \"\$@\" >> '${sudo_calls}'
    local cmd=\"\$1\"
    if [[ \"\$cmd\" == 'cp' ]]; then
      mkdir -p '${APP_DIR}'
      touch '${APP_DIR}/chrome-sandbox'
    fi
  "

  cd "$WORKDIR"
  run install_binaries "${APP_DIR}" "/tmp/ag-link"
  [ "$status" -eq 0 ]
  grep -q "chown root:root" "$sudo_calls"
  grep -q "chmod 4755" "$sudo_calls"
}

@test "install_binaries skips chrome-sandbox fix when not present" {
  mkdir -p "${WORKDIR}/usr/share/antigravity"
  touch "${WORKDIR}/usr/share/antigravity/antigravity"

  local sudo_calls="${WORKDIR}/sudo_calls"
  make_stub sudo "echo \"\$@\" >> '${sudo_calls}'"

  cd "$WORKDIR"
  run install_binaries "/opt/antigravity-test" "/tmp/ag-link"
  [ "$status" -eq 0 ]
  ! grep -q "chown root:root" "$sudo_calls"
}

@test "install_binaries patches product.json safely" {
  local APP_DIR="${WORKDIR}/opt/ag"
  local PRODUCT_JSON_PATH="usr/share/antigravity/resources/app/product.json"
  mkdir -p "${WORKDIR}/$(dirname "$PRODUCT_JSON_PATH")"
  
  # Create a sample product.json with problematic entries
  printf '%s\n' '{
    "nameShort": "Antigravity",
    "extensionEnabledApiProposals": {
        "attributableCoverage": ["ext1"],
        "contribIssueReporter": ["ext2"],
        "lmTools": ["ext3"],
        "stableFeature": ["ext4"]
    }
}' > "${WORKDIR}/${PRODUCT_JSON_PATH}"

  local sudo_calls="${WORKDIR}/sudo_calls"
  # Stub sudo to be a transparent wrapper for most commands, but bypass root-only actions
  make_stub sudo "
    if [[ \"\$1\" == '-A' ]]; then shift; fi
    local cmd=\"\$1\"
    case \"\$cmd\" in
      chown|chmod)
        # Bypassing root-only permissions in tests
        exit 0
        ;;
      *)
        # Execute the actual command as the current test user
        \"\$@\"
        ;;
    esac
  "

  cd "$WORKDIR"
  run install_binaries "${APP_DIR}" "/tmp/ag-link"
  [ "$status" -eq 0 ]
  
  local patched_json="${APP_DIR}/resources/app/product.json"
  [ -f "$patched_json" ]
  
  # Verify it's valid JSON
  python3 -m json.tool "$patched_json" > /dev/null
  
  # Verify entries were removed
  [ "$(grep -c "attributableCoverage" "$patched_json")" -eq 0 ]
  [ "$(grep -c "contribIssueReporter" "$patched_json")" -eq 0 ]
  [ "$(grep -c "lmTools" "$patched_json")" -eq 0 ]
  # Verify other entries remain
  grep -q "stableFeature" "$patched_json"
}
