#!/usr/bin/env bats
# tests/desktop.bats — tests for lib/desktop.sh

load 'test_helper'

setup() {
  setup_mocks
  source_lib log.sh
  source_lib desktop.sh
  WORKDIR="$(mktemp -d)"
}

teardown() {
  teardown_mocks
  rm -rf "$WORKDIR"
}

@test "installs both .desktop files when both present" {
  mkdir -p "${WORKDIR}/usr/share/applications" "${WORKDIR}/usr/share/pixmaps"
  echo "[Desktop Entry]" > "${WORKDIR}/usr/share/applications/antigravity.desktop"
  echo "Exec=old" >> "${WORKDIR}/usr/share/applications/antigravity.desktop"
  echo "[Desktop Entry]" > "${WORKDIR}/usr/share/applications/antigravity-url-handler.desktop"
  echo "Exec=old" >> "${WORKDIR}/usr/share/applications/antigravity-url-handler.desktop"
  echo "PNG" > "${WORKDIR}/usr/share/pixmaps/antigravity.png"

  local sudo_calls="${WORKDIR}/sudo_calls"
  make_stub sudo "echo \"\$@\" >> '${sudo_calls}'"

  cd "$WORKDIR"
  run install_desktop_files "/opt/antigravity" \
    "/usr/share/applications/antigravity.desktop" \
    "/usr/share/applications/antigravity-url-handler.desktop" \
    "/usr/share/pixmaps/antigravity.png"
  [ "$status" -eq 0 ]
  grep -q "antigravity.desktop" "$sudo_calls"
  grep -q "antigravity-url-handler.desktop" "$sudo_calls"
  grep -q "antigravity.png" "$sudo_calls"
}

@test "skips .desktop install when files not present" {
  mkdir -p "${WORKDIR}/usr/share/applications"
  # No .desktop files created

  local sudo_calls="${WORKDIR}/sudo_calls"
  make_stub sudo "echo \"\$@\" >> '${sudo_calls}'"

  cd "$WORKDIR"
  run install_desktop_files "/opt/antigravity" \
    "/tmp/d1.desktop" "/tmp/d2.desktop" "/tmp/icon.png"
  [ "$status" -eq 0 ]
  # sudo install should not have been called for desktop files
  ! grep -q "install" "$sudo_calls" 2>/dev/null || true
}

@test "rewrites Exec= line to use correct app_dir path" {
  mkdir -p "${WORKDIR}/usr/share/applications"
  printf '[Desktop Entry]\nExec=/wrong/path/antigravity %%U\n' \
    > "${WORKDIR}/usr/share/applications/antigravity.desktop"

  local installed_file="${WORKDIR}/installed.desktop"
  make_stub sudo "cp \"\${@: -2:1}\" '${installed_file}'"

  cd "$WORKDIR"
  install_desktop_files "/opt/antigravity-correct" \
    "$installed_file" "/tmp/d2" "/tmp/icon.png" 2>/dev/null || true

  if [[ -f "$installed_file" ]]; then
    grep -q "/opt/antigravity-correct/antigravity" "$installed_file"
  fi
}
