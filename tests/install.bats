#!/usr/bin/env bats
# tests/install.bats — tests for lib/install.sh

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
  mkdir -p "${WORKDIR}/usr/share/antigravity"
  touch "${WORKDIR}/usr/share/antigravity/antigravity"
  touch "${WORKDIR}/usr/share/antigravity/chrome-sandbox"

  local sudo_calls="${WORKDIR}/sudo_calls"
  make_stub sudo "echo \"\$@\" >> '${sudo_calls}'"

  cd "$WORKDIR"
  run install_binaries "/opt/antigravity-test" "/tmp/ag-link"
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
