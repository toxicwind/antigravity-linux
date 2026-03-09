#!/usr/bin/env bats
# tests/uninstall.bats — tests for lib/uninstall.sh

load 'test_helper'

setup() {
  setup_mocks
  source_lib log.sh
  source_lib uninstall.sh
  WORKDIR="$(mktemp -d)"
}

teardown() {
  teardown_mocks
  rm -rf "$WORKDIR"
}

@test "calls sudo to remove app dir, symlink, desktop files, and icon" {
  local sudo_calls="${WORKDIR}/sudo_calls"
  make_stub sudo "echo \"\$@\" >> '${sudo_calls}'"

  run uninstall "/opt/ag" "/usr/local/bin/ag" "/usr/share/applications/ag.desktop" \
    "/usr/share/applications/ag-url.desktop" "/usr/share/pixmaps/ag.png"
  [ "$status" -eq 0 ]
  grep -q "\-rf /opt/ag" "$sudo_calls"
  grep -q "\-f /usr/local/bin/ag" "$sudo_calls"
  grep -q "ag.png" "$sudo_calls"
}

@test "succeeds even when sudo fails (uses || true internally)" {
  make_stub sudo "exit 1"
  run uninstall "/opt/ag" "/usr/local/bin/ag" "/d1" "/d2" "/icon.png"
  [ "$status" -eq 0 ]
}

@test "prints removal confirmation message" {
  make_stub sudo "exit 0"
  run uninstall "/opt/ag" "/bin/ag" "/d1" "/d2" "/icon.png"
  [[ "$output" == *"removed"* ]]
}
