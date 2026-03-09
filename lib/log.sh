#!/usr/bin/env bash
# lib/log.sh — Coloured logging helpers

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'

log_info()  { echo -e "${CYAN}[*]${RESET} $*"; }
log_ok()    { echo -e "${GREEN}[+]${RESET} $*"; }
log_error() { echo -e "${RED}[-]${RESET} $*" >&2; }
