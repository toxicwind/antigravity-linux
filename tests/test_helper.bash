#!/usr/bin/env bash
# tests/test_helper.bash — shared setup for all bats test files
bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export FIXTURES="${REPO_ROOT}/tests/fixtures"

# Create a fake bin dir and prepend it to PATH so we can stub system commands
setup_mocks() {
  export ANTIGRAVITY_TESTING=1
  MOCK_BIN="$(mktemp -d)"
  export PATH="${MOCK_BIN}:${PATH}"
  export MOCK_BIN
}

teardown_mocks() {
  rm -rf "${MOCK_BIN:-}"
}

# Write an executable stub to MOCK_BIN
make_stub() {
  local cmd="$1"; shift
  local body="${*:-echo stubbed $cmd}"
  printf '#!/usr/bin/env bash\n%s\n' "$body" > "${MOCK_BIN}/${cmd}"
  chmod +x "${MOCK_BIN}/${cmd}"
}

# Stub that always succeeds (default)
stub_ok()   { make_stub "$1" "exit 0"; }

# Stub that always fails
stub_fail() { make_stub "$1" "exit 1"; }

# Source a lib module (with mocked PATH already active)
source_lib() {
  # shellcheck source=/dev/null
  source "${REPO_ROOT}/lib/${1}"
}
