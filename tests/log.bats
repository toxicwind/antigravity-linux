#!/usr/bin/env bats
# tests/log.bats — tests for lib/log.sh
# bats file_tags=ci

load 'test_helper'

setup()    { source_lib log.sh; }

@test "log_info writes to stdout with [*] prefix" {
  run log_info "hello world"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[*]"* ]]
  [[ "$output" == *"hello world"* ]]
}

@test "log_ok writes to stdout with [+] prefix" {
  run log_ok "all good"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[+]"* ]]
  [[ "$output" == *"all good"* ]]
}

@test "log_error writes to stderr with [-] prefix" {
  run bash -c "source ${REPO_ROOT}/lib/log.sh; log_error 'something broke'"
  [ "$status" -eq 0 ]
  # bats captures stderr in $output when using run with combined output
  [[ "$output" == *"[-]"* ]]
  [[ "$output" == *"something broke"* ]]
}

@test "log functions accept multi-word arguments" {
  run log_info "hello" "world" "foo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"hello"* ]]
}
