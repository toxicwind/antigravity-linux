#!/usr/bin/env bats
# tests/install.bats — tests for lib/install.sh
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
  make_stub sudo "
    echo \"\$@\" >> '${sudo_calls}'
    if [[ \"\$1\" == 'cp' ]]; then
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
  cat <<EOF > "${WORKDIR}/${PRODUCT_JSON_PATH}"
{
    "nameShort": "Antigravity",
    "extensionEnabledApiProposals": {
        "attributableCoverage": ["ext1"],
        "contribIssueReporter": ["ext2"],
        "lmTools": ["ext3"],
        "stableFeature": ["ext4"]
    }
}
EOF

  local sudo_calls="${WORKDIR}/sudo_calls"
  # Stub sudo to mimic real file movement and then allow python patch to run on it
  # Since we are in a test, python script will run as the current user.
  # We need to make sure the file exists in the simulated APP_DIR.
  make_stub sudo "
    if [[ \"\$1\" == 'cp' ]]; then
      mkdir -p \"\${@: -1}\"
      cp -r usr/share/antigravity/* \"\${@: -1}/\"
    fi
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
