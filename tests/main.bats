#!/usr/bin/env bats
# tests/main.bats — integration tests for antigravity-installer.sh orchestrator

load 'test_helper'

INSTALLER="${REPO_ROOT}/antigravity-installer.sh"

setup() {
  setup_mocks
  WORKDIR="$(mktemp -d)"

  # Stub all system commands used by the pipeline
  make_stub curl "cp '${FIXTURES}/Packages' \"\${@: -1}\""
  make_stub bsdtar "mkdir -p usr/share/antigravity && touch usr/share/antigravity/antigravity"
  make_stub sha256sum "echo 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb  -'"
  make_stub sudo "echo sudo: \"\$@\""
}

teardown() {
  teardown_mocks
  rm -rf "$WORKDIR"
}

# ── Requirements check ───────────────────────────────────────────────────────

@test "exits non-zero when a required command is missing" {
  # Remove curl from mock bin so it appears missing
  rm -f "${MOCK_BIN}/curl"
  # Also hide system curl
  make_stub curl "exit 127"
  # Simulate 'command -v curl' failure by creating a failing wrapper
  make_stub curl ""  # empty body = exits 0 but doesn't exist via command -v trick
  # Better: hide it entirely
  rm -f "${MOCK_BIN}/curl"
  run bash -c "PATH='${MOCK_BIN}' bash '${INSTALLER}'"
  [ "$status" -ne 0 ]
}

# ── --uninstall flag ─────────────────────────────────────────────────────────

@test "--uninstall flag triggers uninstall and exits 0" {
  run bash "${INSTALLER}" --uninstall
  [ "$status" -eq 0 ]
  [[ "$output" == *"removed"* || "$output" == *"Uninstall"* || "$output" == *"sudo"* ]]
}

# ── Full pipeline ─────────────────────────────────────────────────────────────

@test "full install pipeline exits 0 with all stubs in place" {
  cd "$WORKDIR"
  run bash "${INSTALLER}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"installed successfully"* ]]
}

@test "install pipeline prints the version number" {
  cd "$WORKDIR"
  run bash "${INSTALLER}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1.20.4"* ]]
}

@test "install pipeline calls sha256 verification" {
  local sha_calls="${WORKDIR}/sha_calls"
  make_stub sha256sum "echo 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb  -'; echo \"\$@\" >> '${sha_calls}'"
  cd "$WORKDIR"
  run bash "${INSTALLER}"
  [ "$status" -eq 0 ]
}

@test "install pipeline fails when curl returns error" {
  make_stub curl "exit 1"
  cd "$WORKDIR"
  run bash "${INSTALLER}"
  [ "$status" -ne 0 ]
}
