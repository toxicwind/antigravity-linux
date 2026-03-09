#!/usr/bin/env bats
# tests/pkg_index.bats — tests for lib/pkg_index.sh (critical: awk EOF-flush fix)

load 'test_helper'

setup() {
  setup_mocks
  source_lib log.sh
  source_lib pkg_index.sh
}

teardown() { teardown_mocks; }

# ── Happy path: last entry has NO trailing blank line (the bug regression test) ──

@test "picks latest version when last entry has no trailing blank line" {
  make_stub curl "cp '${FIXTURES}/Packages' \"\${@: -1}\""
  # Call directly (not via `run`) so exported vars are visible in parent shell
  fetch_latest_package "/tmp/Packages.$$" "https://fake-apt-base"
  [[ "$DEBVER"      == "1.20.4-1772839303" ]]
  [[ "$DEBFILENAME" == *"1.20.4"* ]]
  [[ "$DEBSHA256"   == "bbbb"* ]]
}

@test "picks latest version when single entry has trailing blank line" {
  make_stub curl "cp '${FIXTURES}/Packages.single_with_newline' \"\${@: -1}\""
  fetch_latest_package "/tmp/Packages.$$" "https://fake-apt-base"
  [[ "$DEBVER" == "1.20.3-old" ]]
}

@test "exports DEBVER DEBFILENAME DEBSHA256" {
  make_stub curl "cp '${FIXTURES}/Packages' \"\${@: -1}\""
  fetch_latest_package "/tmp/Packages.$$" "https://fake-apt-base"
  [ -n "$DEBVER" ]
  [ -n "$DEBFILENAME" ]
  [ -n "$DEBSHA256" ]
}

# ── Failure paths ────────────────────────────────────────────────────────────

@test "fails when curl errors" {
  stub_fail curl
  run fetch_latest_package "/tmp/Packages.$$" "https://fake-apt-base"
  [ "$status" -ne 0 ]
}

@test "fails when no antigravity entry in Packages index" {
  make_stub curl "cp '${FIXTURES}/Packages.no_entry' \"\${@: -1}\""
  run fetch_latest_package "/tmp/Packages.$$" "https://fake-apt-base"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Failed to parse"* ]]
}
