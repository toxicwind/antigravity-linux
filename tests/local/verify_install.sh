#!/usr/bin/env bash
# tests/local/verify_install.sh
#
# LOCAL-ONLY integration verification — run this on a real Arch/CachyOS machine
# to confirm the full installer works end-to-end with real packages.
#
# Usage:
#   bash tests/local/verify_install.sh
#   bash tests/local/verify_install.sh --uninstall
#
# This script is NOT run in CI. It is the human sign-off for a real system run.
# After a successful run, commit the output of --report to VERIFIED.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTALLER="${SCRIPT_DIR}/antigravity-installer.sh"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
OS_PRETTY="$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo 'Unknown')"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
pass() { echo -e "${GREEN}[PASS]${RESET} $*"; }
fail() { echo -e "${RED}[FAIL]${RESET} $*"; FAILURES=$((FAILURES+1)); }
info() { echo -e "${CYAN}[INFO]${RESET} $*"; }

FAILURES=0

if [[ "${1:-}" == "--uninstall" ]]; then
  bash "$INSTALLER" --uninstall
  exit 0
fi

echo
info "Running local integration verification on: ${OS_PRETTY}"
info "Timestamp: ${TIMESTAMP}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Installer runs without error
info "Running installer..."
if bash "$INSTALLER"; then
  pass "Installer exited 0"
else
  fail "Installer failed"
fi

# 2. Binary exists and is executable
if [[ -x /usr/local/bin/antigravity ]]; then
  pass "/usr/local/bin/antigravity symlink exists and is executable"
else
  fail "/usr/local/bin/antigravity not found or not executable"
fi

# 3. /opt/antigravity present
if [[ -d /opt/antigravity ]]; then
  pass "/opt/antigravity directory installed"
else
  fail "/opt/antigravity not found"
fi

# 4. Desktop entry present
if [[ -f /usr/share/applications/antigravity.desktop ]]; then
  pass "Desktop entry installed"
else
  fail "Desktop entry missing"
fi

# 5. Version is parseable
if VER=$(grep '"version"' /opt/antigravity/resources/app/package.json 2>/dev/null | head -1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+'); then
  pass "Antigravity version: ${VER}"
else
  fail "Could not parse version from installed package.json"
fi

# 6. chrome-sandbox has correct permissions
if [[ -f /opt/antigravity/chrome-sandbox ]]; then
  PERMS=$(stat -c "%a" /opt/antigravity/chrome-sandbox)
  OWNER=$(stat -c "%U" /opt/antigravity/chrome-sandbox)
  if [[ "$PERMS" == "4755" && "$OWNER" == "root" ]]; then
    pass "chrome-sandbox: setuid root (4755)"
  else
    fail "chrome-sandbox: wrong perms ($PERMS) or owner ($OWNER)"
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $FAILURES -eq 0 ]]; then
  echo -e "${GREEN}All checks passed on ${OS_PRETTY} at ${TIMESTAMP}${RESET}"
  echo
  echo "To record this as a verified run, add to VERIFIED.md:"
  echo "  | ${TIMESTAMP} | ${OS_PRETTY} | ${VER:-unknown} | ✅ |"
else
  echo -e "${RED}${FAILURES} check(s) failed.${RESET}"
  exit 1
fi
